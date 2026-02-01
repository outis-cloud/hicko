use maxminddb::Reader;
use std::net::IpAddr;

pub struct GeoDB {
    reader: std::sync::Arc<Reader<Vec<u8>>>,
}

impl Clone for GeoDB {
    fn clone(&self) -> Self {
        Self {
            reader: self.reader.clone(),
        }
    }
}

impl GeoDB {
    pub fn open_from_bytes(bytes: Vec<u8>) -> Result<Self, maxminddb::MaxMindDBError> {
        let reader = Reader::from_source(bytes)?;
        Ok(Self {
            reader: std::sync::Arc::new(reader),
        })
    }

    pub fn country(&self, ip: IpAddr) -> Option<String> {
        if let Ok(country) = self.reader.lookup::<maxminddb::geoip2::Country>(ip) {
            if let Some(country) = country.country {
                return country.iso_code.map(|s| s.to_string());
            }
        }
        None
    }
}

/// GeoDNS rule for matching and routing based on geographic criteria.
#[derive(Clone, Debug)]
pub struct GeoRule {
    pub id: String,
    pub match_type: String,  // "country", "region", "continent"
    pub match_value: String, // e.g., "US", "EU"
    pub target: String,      // IP address or hostname to return
}

/// GeoRule engine: evaluates rules and returns best target based on client IP
pub struct GeoRuleEngine {
    rules: Vec<GeoRule>,
    db: Option<GeoDB>,
}

impl GeoRuleEngine {
    /// Create a new GeoRule engine, optionally with a GeoDB
    pub fn new(db: Option<GeoDB>) -> Self {
        Self {
            rules: Vec::new(),
            db,
        }
    }

    /// Add a rule to the engine
    pub fn add_rule(&mut self, rule: GeoRule) {
        self.rules.push(rule);
    }

    /// Set all rules at once
    pub fn set_rules(&mut self, rules: Vec<GeoRule>) {
        self.rules = rules;
    }

    /// Evaluate rules for a client IP and return the target address
    /// Returns Some(target) if a rule matches, None if no match (use default)
    pub fn evaluate(&self, client_ip: IpAddr) -> Option<String> {
        if self.db.is_none() {
            return None; // No GeoIP database available
        }
        
        let db = self.db.as_ref().unwrap();
        
        // Get the client's country
        let country = db.country(client_ip)?;
        
        // Find first matching rule
        for rule in &self.rules {
            match rule.match_type.as_str() {
                "country" => {
                    if rule.match_value.eq_ignore_ascii_case(&country) {
                        return Some(rule.target.clone());
                    }
                }
                "region" | "continent" => {
                    // For now, treat as simple string match (can be extended)
                    if rule.match_value.eq_ignore_ascii_case(&country) {
                        return Some(rule.target.clone());
                    }
                }
                _ => {}
            }
        }
        
        None // No matching rule found
    }

    /// Get all rules
    pub fn rules(&self) -> &[GeoRule] {
        &self.rules
    }
}
