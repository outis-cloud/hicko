use actix_web::{web, App, HttpResponse, HttpServer, Responder, HttpRequest, http::header};
use serde::{Deserialize, Serialize};
use log::{info, warn};
use tokio_postgres::{NoTls, Client as PgClient};
use uuid::Uuid;
use jsonwebtoken::{EncodingKey, DecodingKey, Header, Validation, encode, decode, TokenData};
use argon2::{Argon2, password_hash::{SaltString, PasswordHasher, PasswordVerifier, PasswordHash}};
use rand_core::OsRng;

#[derive(Clone, Serialize, Deserialize)]
struct Claims {
    sub: String,
    role: String,
    exp: usize,
}

#[derive(Clone, Serialize, Deserialize)]
struct ServerInfo {
    id: String,
    name: String,
    address: String,
    region: Option<String>,
}

#[derive(Clone, Serialize, Deserialize)]
struct ZoneRecord {
    name: String,
    record_type: String,
    value: String,
    ttl: u32,
}

#[derive(Clone, Serialize, Deserialize)]
struct Zone {
    id: String,
    domain: String,
    records: Vec<ZoneRecord>,
}

#[derive(Clone)]
struct AppState {
    db: std::sync::Arc<PgClient>,
    jwt_secret: String,
}

struct GeoState {
    db: Option<geodns::GeoDB>,
}

#[derive(Clone)]
struct FullState {
    inner: AppState,
    geo: std::sync::Arc<tokio::sync::Mutex<GeoState>>,
}

async fn health() -> impl Responder {
    HttpResponse::Ok().json(serde_json::json!({"status":"ok"}))
}

async fn migrate_db(client: &PgClient) -> Result<(), tokio_postgres::Error> {
    client.batch_execute(
        "CREATE TABLE IF NOT EXISTS users (id UUID PRIMARY KEY, username TEXT UNIQUE NOT NULL, password_hash TEXT NOT NULL, role TEXT NOT NULL);
         CREATE TABLE IF NOT EXISTS servers (id UUID PRIMARY KEY, name TEXT NOT NULL, address TEXT NOT NULL, region TEXT);
         CREATE TABLE IF NOT EXISTS zones (id UUID PRIMARY KEY, domain TEXT NOT NULL, owner UUID);
         CREATE TABLE IF NOT EXISTS records (id UUID PRIMARY KEY, zone_id UUID REFERENCES zones(id) ON DELETE CASCADE, name TEXT, type TEXT, value TEXT, ttl INT);
         CREATE TABLE IF NOT EXISTS agents (id UUID PRIMARY KEY, name TEXT, addr TEXT, last_heartbeat TIMESTAMP WITH TIME ZONE DEFAULT now());
         CREATE TABLE IF NOT EXISTS georules (id UUID PRIMARY KEY, zone_id UUID REFERENCES zones(id) ON DELETE CASCADE, match_type TEXT, match_value TEXT, target TEXT);",
    ).await?;
    Ok(())
}

#[derive(Deserialize)]
struct LoginRequest {
    username: String,
    password: String,
}

#[derive(Serialize)]
struct LoginResponse {
    token: String,
}

async fn login(body: web::Json<LoginRequest>, data: web::Data<AppState>) -> impl Responder {
    if let Ok(row) = (&*data.db).query_one("SELECT id::text, password_hash, role FROM users WHERE username = $1", &[&body.username]).await {
        let id_str: String = row.get(0);
        let id = id_str.clone();
        let password_hash: String = row.get(1);
        let role: Option<String> = row.get(2);
        if let Ok(hash) = PasswordHash::new(&password_hash) {
            if Argon2::default().verify_password(body.password.as_bytes(), &hash).is_ok() {
                let exp = (chrono::Utc::now() + chrono::Duration::hours(8)).timestamp() as usize;
                let claims = Claims { sub: id.to_string(), role: role.clone().unwrap_or("user".to_string()), exp };
                let token = encode(&Header::default(), &claims, &EncodingKey::from_secret(data.jwt_secret.as_bytes())).unwrap();
                return HttpResponse::Ok().json(LoginResponse { token });
            }
        }
    }
    HttpResponse::Unauthorized().finish()
}

async fn create_user(req: web::Json<LoginRequest>, data: web::Data<AppState>) -> impl Responder {
    let mut rng = OsRng;
    let salt = SaltString::generate(&mut rng);
    let argon2 = Argon2::default();
    let password_hash = argon2.hash_password(req.password.as_bytes(), &salt).unwrap().to_string();
    let id = Uuid::new_v4();
    let role = "user";
    let id_str = id.to_string();
    let res = (&*data.db).execute("INSERT INTO users (id, username, password_hash, role) VALUES ($1::uuid, $2, $3, $4)", &[&id_str, &req.username, &password_hash, &role]).await;
    match res {
        Ok(_) => HttpResponse::Created().json(serde_json::json!({"id": id.to_string()})),
        Err(e) => {
            warn!("create_user error: {}", e);
            HttpResponse::InternalServerError().finish()
        }
    }
}

fn auth_from_header(req: &HttpRequest, secret: &str) -> Option<TokenData<Claims>> {
    if let Some(auth) = req.headers().get(header::AUTHORIZATION) {
        if let Ok(s) = auth.to_str() {
            if s.starts_with("Bearer ") {
                let token = &s[7..];
                if let Ok(data) = decode::<Claims>(token, &DecodingKey::from_secret(secret.as_bytes()), &Validation::default()) {
                    return Some(data);
                }
            }
        }
    }
    None
}

async fn list_servers(data: web::Data<AppState>, req: HttpRequest) -> impl Responder {
    if auth_from_header(&req, &data.jwt_secret).is_none() {
        return HttpResponse::Unauthorized().finish();
    }
    let rows = (&*data.db).query("SELECT id::text, name, address, region FROM servers", &[]).await.unwrap_or_default();
    let servers: Vec<ServerInfo> = rows.into_iter().map(|r| ServerInfo { id: r.get::<usize, String>(0), name: r.get(1), address: r.get(2), region: r.get(3) }).collect();
    HttpResponse::Ok().json(servers)
}

#[derive(Deserialize)]
struct CreateServerReq {
    name: String,
    address: String,
    region: Option<String>,
}

async fn create_server(body: web::Json<CreateServerReq>, data: web::Data<AppState>, req: HttpRequest) -> impl Responder {
    if let Some(tok) = auth_from_header(&req, &data.jwt_secret) {
        if tok.claims.role != "admin" {
            return HttpResponse::Forbidden().finish();
        }
    } else {
        return HttpResponse::Unauthorized().finish();
    }
    let id = Uuid::new_v4();
    let id_str = id.to_string();
    let res = (&*data.db).execute("INSERT INTO servers (id, name, address, region) VALUES ($1::uuid, $2, $3, $4)", &[&id_str, &body.name, &body.address, &body.region]).await;
    match res {
        Ok(_) => HttpResponse::Created().json(serde_json::json!({"id": id.to_string()})),
        Err(e) => {
            warn!("create_server error: {}", e);
            HttpResponse::InternalServerError().finish()
        }
    }
}

#[derive(Deserialize)]
struct AgentRegistration {
    name: String,
    addr: String,
}

async fn agent_register(body: web::Json<AgentRegistration>, data: web::Data<AppState>) -> impl Responder {
    let id = Uuid::new_v4();
    let id_str = id.to_string();
    let res = (&*data.db).execute("INSERT INTO agents (id, name, addr) VALUES ($1::uuid, $2, $3)", &[&id_str, &body.name, &body.addr]).await;
    match res {
        Ok(_) => HttpResponse::Created().json(serde_json::json!({"id": id.to_string()})),
        Err(e) => {
            warn!("agent_register error: {}", e);
            HttpResponse::InternalServerError().finish()
        }
    }
}

async fn agent_heartbeat(body: web::Json<AgentRegistration>, data: web::Data<AppState>) -> impl Responder {
    let res = (&*data.db).execute("UPDATE agents SET last_heartbeat = now() WHERE addr = $1", &[&body.addr]).await;
    match res {
        Ok(r) => {
            if r == 0 {
                return HttpResponse::NotFound().finish();
            }
            HttpResponse::Ok().finish()
        }
        Err(e) => { warn!("agent_heartbeat error: {}", e); HttpResponse::InternalServerError().finish() }
    }
}

#[derive(Deserialize)]
#[allow(dead_code)]
struct StartDnsReq {
    id: String,
    bind: String,
}

async fn start_dns_server(_body: web::Json<StartDnsReq>, _data: web::Data<FullState>) -> impl Responder {
    HttpResponse::NotImplemented().body("dns_manager not enabled in this build")
}

#[derive(Deserialize)]
#[allow(dead_code)]
struct StopDnsReq {
    id: String,
}

async fn stop_dns_server(_body: web::Json<StopDnsReq>, _data: web::Data<FullState>) -> impl Responder {
    HttpResponse::NotImplemented().body("dns_manager not enabled in this build")
}

#[derive(Deserialize)]
struct CreateGeoRuleReq {
    zone_id: String,
    match_type: String,
    match_value: String,
    target: String,
}

async fn create_georule(body: web::Json<CreateGeoRuleReq>, data: web::Data<FullState>, req: HttpRequest) -> impl Responder {
    if auth_from_header(&req, &data.inner.jwt_secret).is_none() { return HttpResponse::Unauthorized().finish(); }
    let id = Uuid::new_v4();
    let zone_uuid = match Uuid::parse_str(&body.zone_id) {
        Ok(z) => z,
        Err(_) => return HttpResponse::BadRequest().body("invalid zone_id"),
    };
    let id_str = id.to_string();
    let zone_str = zone_uuid.to_string();
    let res = (&*data.inner.db).execute("INSERT INTO georules (id, zone_id, match_type, match_value, target) VALUES ($1::uuid, $2::uuid, $3, $4, $5)", &[&id_str, &zone_str, &body.match_type, &body.match_value, &body.target]).await;
    match res {
        Ok(_) => HttpResponse::Created().json(serde_json::json!({"id": id.to_string()})),
        Err(e) => { warn!("create_georule error: {}", e); HttpResponse::InternalServerError().finish() }
    }
}

async fn list_georules(data: web::Data<FullState>, req: HttpRequest) -> impl Responder {
    if auth_from_header(&req, &data.inner.jwt_secret).is_none() { return HttpResponse::Unauthorized().finish(); }
    let rows = (&*data.inner.db).query("SELECT id::text, zone_id::text, match_type, match_value, target FROM georules", &[]).await.unwrap_or_default();
    let out: Vec<_> = rows.into_iter().map(|r| serde_json::json!({"id": r.get::<usize, String>(0), "zone_id": r.get::<usize, String>(1), "match_type": r.get::<usize, String>(2), "match_value": r.get::<usize, String>(3), "target": r.get::<usize, String>(4)})).collect();
    HttpResponse::Ok().json(out)
}

#[derive(Deserialize)]
struct CreateZoneReq {
    domain: String,
}

async fn list_zones(data: web::Data<AppState>, _req: HttpRequest) -> impl Responder {
    let rows = (&*data.db).query("SELECT id::text, domain FROM zones", &[]).await.unwrap_or_default();
    let zones: Vec<Zone> = rows.into_iter().map(|r| Zone { id: r.get::<usize, String>(0), domain: r.get(1), records: vec![] }).collect();
    HttpResponse::Ok().json(zones)
}

async fn create_zone(body: web::Json<CreateZoneReq>, data: web::Data<AppState>, req: HttpRequest) -> impl Responder {
    if auth_from_header(&req, &data.jwt_secret).is_none() {
        return HttpResponse::Unauthorized().finish();
    }
    let id = Uuid::new_v4();
    let id_str = id.to_string();
    let res = (&*data.db).execute("INSERT INTO zones (id, domain) VALUES ($1::uuid, $2)", &[&id_str, &body.domain]).await;
    match res {
        Ok(_) => HttpResponse::Created().json(serde_json::json!({"id": id.to_string()})),
        Err(e) => {
            warn!("create_zone error: {}", e);
            HttpResponse::InternalServerError().finish()
        }
    }
}

#[derive(Deserialize)]
struct GeoResolveRequest {
    zone_id: String,
    client_ip: String,
}

/// Resolve a DNS response for a zone based on client's geographic location.
/// Uses GeoRules to determine which target address to return.
async fn resolve_by_geo(body: web::Json<GeoResolveRequest>, data: web::Data<FullState>) -> impl Responder {
    // Parse client IP
    let client_ip = match body.client_ip.parse::<std::net::IpAddr>() {
        Ok(ip) => ip,
        Err(_) => return HttpResponse::BadRequest().body("invalid client IP"),
    };

    // Fetch georules for this zone from DB
    let rows = (&*data.inner.db)
        .query(
            "SELECT id::text, match_type, match_value, target FROM georules WHERE zone_id::text = $1",
            &[&body.zone_id],
        )
        .await
        .unwrap_or_default();

    let rules: Vec<geodns::GeoRule> = rows
        .into_iter()
        .map(|r| geodns::GeoRule {
            id: r.get::<usize, String>(0),
            match_type: r.get::<usize, String>(1),
            match_value: r.get::<usize, String>(2),
            target: r.get::<usize, String>(3),
        })
        .collect();

    // Get GeoIP DB from state
    let geo_state = data.geo.lock().await;
    let db = geo_state.db.as_ref().cloned();

    // Create rule engine and evaluate
    let mut engine = geodns::GeoRuleEngine::new(db);
    engine.set_rules(rules);

    // Evaluate and return target
    match engine.evaluate(client_ip) {
        Some(target) => HttpResponse::Ok().json(serde_json::json!({"target": target})),
        None => HttpResponse::Ok().json(serde_json::json!({"target": None::<String>, "message": "no matching geo rule"})),
    }
}

// Placeholder: function to push configuration to agents (secure HTTPS/gRPC in production)
#[allow(dead_code)]
async fn push_config_to_agent(_agent_id: &str) {
    // TODO: implement secure config push
}

#[derive(Deserialize)]
#[allow(dead_code)]
struct ConfigPushRequest {
    agent_id: String,
    zone_id: String,
    zone_config: serde_json::Value,
}

#[derive(Serialize)]
struct ConfigPushResponse {
    success: bool,
    message: String,
}

/// Push DNS zone configuration to an agent securely (mTLS placeholder)
/// In production: use rustls with client certificates for authentication
async fn push_config_to_agents(
    body: web::Json<ConfigPushRequest>,
    data: web::Data<FullState>,
    req: HttpRequest,
) -> impl Responder {
    // Verify admin role
    if let Some(tok) = auth_from_header(&req, &data.inner.jwt_secret) {
        if tok.claims.role != "admin" {
            return HttpResponse::Forbidden().body("admin role required");
        }
    } else {
        return HttpResponse::Unauthorized().finish();
    }

    // Fetch agent details from DB
    let rows = (&*data.inner.db)
        .query("SELECT id::text, addr FROM agents WHERE id::text = $1", &[&body.agent_id])
        .await
        .unwrap_or_default();

    if rows.is_empty() {
        return HttpResponse::NotFound().body("agent not found");
    }

    let _agent_addr: String = rows[0].get(1);

    // In production, this would:
    // 1. Use mTLS to securely connect to agent at agent_addr
    // 2. Sign config with control plane private key
    // 3. Send config blob to agent
    // 4. Verify agent signature on acknowledgment

    // For now, log the config push intention
    info!(
        "Config push scheduled for agent {} with zone {}",
        body.agent_id, body.zone_id
    );

    HttpResponse::Ok().json(ConfigPushResponse {
        success: true,
        message: "config push queued".to_string(),
    })
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init();
    info!("Starting control API...");

    let database_url = std::env::var("DATABASE_URL").unwrap_or_else(|_| "host=db user=postgres password=password dbname=hickory".to_string());
    let jwt_secret = std::env::var("JWT_SECRET").unwrap_or_else(|_| "replace_with_a_super_secret".to_string());

    let (client, connection) = tokio_postgres::connect(&database_url, NoTls).await.expect("cannot connect to db");
    // spawn connection driver
    tokio::spawn(async move {
        if let Err(e) = connection.await {
            warn!("postgres connection error: {}", e);
        }
    });
    migrate_db(&client).await.expect("db migrate failed");
    let app_state = AppState { db: std::sync::Arc::new(client), jwt_secret: jwt_secret.clone() };

    // Load GeoIP DB if provided
    let geo_db = std::env::var("GEOIP_DB_PATH").ok().and_then(|p| {
        std::fs::read(p).ok().and_then(|b| geodns::GeoDB::open_from_bytes(b).ok())
    });

    let full_state = FullState { inner: app_state.clone(), geo: std::sync::Arc::new(tokio::sync::Mutex::new(GeoState { db: geo_db })) };

        let app_data = web::Data::new(app_state.clone());
    let full_data = web::Data::new(full_state.clone());

    HttpServer::new(move || {
        App::new()
            .app_data(app_data.clone())
            .app_data(full_data.clone())
            .route("/api/v1/auth/login", web::post().to(login))
            .route("/api/v1/users", web::post().to(create_user))
            .route("/api/v1/servers", web::get().to(list_servers))
            .route("/api/v1/servers", web::post().to(create_server))
                    .route("/api/v1/zones", web::get().to(list_zones))
                    .route("/api/v1/zones", web::post().to(create_zone))
            .route("/api/v1/agents/register", web::post().to(agent_register))
                    .route("/api/v1/agents/heartbeat", web::post().to(agent_heartbeat))
            .route("/api/v1/dns/start", web::post().to(start_dns_server))
            .route("/api/v1/dns/stop", web::post().to(stop_dns_server))
            .route("/api/v1/georules", web::post().to(create_georule))
            .route("/api/v1/georules", web::get().to(list_georules))
            .route("/api/v1/georules/resolve", web::post().to(resolve_by_geo))
            .route("/api/v1/config/push", web::post().to(push_config_to_agents))
            .route("/health", web::get().to(health))
    })
    .bind(("0.0.0.0", 8080))?
    .run()
    .await
}
