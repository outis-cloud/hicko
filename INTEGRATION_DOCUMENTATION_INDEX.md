# 📚 Integration Documentation Index

## 🚀 Start Here (Pick Your Path)

### I want to...

**Run the full integration test** (Recommended)
→ Read: [START_INTEGRATION.md](START_INTEGRATION.md)
→ Run: `bash integrate.sh`

**Get started quickly (5 min)**
→ Read: [START_INTEGRATION.md](START_INTEGRATION.md)

**Understand the complete setup**
→ Read: [INTEGRATION.md](INTEGRATION.md)

**Troubleshoot an issue**
→ Read: [INTEGRATION_TROUBLESHOOTING.md](INTEGRATION_TROUBLESHOOTING.md)

**See what changed**
→ Read: [SCRIPTS_CONSOLIDATED.md](SCRIPTS_CONSOLIDATED.md)

**Understand the architecture**
→ Read: [INTEGRATION_SYSTEM_OVERVIEW.txt](INTEGRATION_SYSTEM_OVERVIEW.txt)

**Verify everything is ready**
→ Read: [READY_TO_TEST.md](READY_TO_TEST.md)

## 📖 Documentation Files

### Quick Reference (5-10 min reads)
| File | Purpose | Read Time |
|------|---------|-----------|
| **START_INTEGRATION.md** | Quick start guide with commands | 5 min |
| **READY_TO_TEST.md** | Verification checklist | 5 min |
| **SCRIPTS_CONSOLIDATED.md** | What was consolidated | 5 min |

### Complete Guides (15-30 min reads)
| File | Purpose | Read Time |
|------|---------|-----------|
| **INTEGRATION.md** | Full usage guide with troubleshooting | 15 min |
| **INTEGRATION_SETUP_COMPLETE.md** | Detailed setup overview | 15 min |
| **INTEGRATION_SYSTEM_OVERVIEW.txt** | Visual diagrams and flows | 10 min |

### Reference Materials
| File | Purpose | Read Time |
|------|---------|-----------|
| **INTEGRATION_TROUBLESHOOTING.md** | Problem solving (reference) | As needed |
| **INTEGRATION_FINAL_SUMMARY.txt** | Executive summary | 5 min |

## 🎯 Task-Based Navigation

### First Time Setup
1. Read: [START_INTEGRATION.md](START_INTEGRATION.md)
2. Run: `bash check_system.sh`
3. Run: `bash integrate.sh`
4. Access: http://localhost:3000

### Development Workflow
1. Run: `bash integrate.sh` (or `bash run_quick_integration.sh`)
2. Code in `/web/ui` and `/crates/control_api`
3. Changes auto-reload via dev servers
4. Run: `bash stop-services.sh` when done

### Troubleshooting
1. Check: [INTEGRATION_TROUBLESHOOTING.md](INTEGRATION_TROUBLESHOOTING.md)
2. Review: `/tmp/hickory-logs/*.log`
3. Verify: `bash check_system.sh`
4. Retry: `bash integrate.sh`

### Understanding Architecture
1. Read: [INTEGRATION_SYSTEM_OVERVIEW.txt](INTEGRATION_SYSTEM_OVERVIEW.txt)
2. Review: `/crates/control_api/README.md`
3. Review: `/web/ui/SETUP.md`
4. Review: [ARCHITECTURE.md](ARCHITECTURE.md)

## 🔍 Quick Lookup

### I need to...

**Start everything**
```bash
bash integrate.sh
```
→ See: [START_INTEGRATION.md](START_INTEGRATION.md)

**Start quickly (skip tests)**
```bash
bash run_quick_integration.sh
```
→ See: [INTEGRATION.md](INTEGRATION.md)

**Stop services**
```bash
bash stop-services.sh
```
→ See: [INTEGRATION.md](INTEGRATION.md)

**Check system**
```bash
bash check_system.sh
```
→ See: [INTEGRATION_TROUBLESHOOTING.md](INTEGRATION_TROUBLESHOOTING.md)

**View logs**
```bash
tail -f /tmp/hickory-logs/api.log
```
→ See: [INTEGRATION.md](INTEGRATION.md)

**Access app**
```
http://localhost:3000
Username: admin
Password: admin123
```
→ See: [START_INTEGRATION.md](START_INTEGRATION.md)

**Fix an issue**
→ See: [INTEGRATION_TROUBLESHOOTING.md](INTEGRATION_TROUBLESHOOTING.md)

**Run tests**
```bash
cd /web/ui
npm run test:e2e
```
→ See: [INTEGRATION.md](INTEGRATION.md)

## 📊 Script Overview

### Main Scripts
- **integrate.sh** - Full production integration (recommended)
- **run_quick_integration.sh** - Quick development mode
- **stop-services.sh** - Service cleanup

### Helper Scripts
- **check_system.sh** - Prerequisite verification
- **verify_production_readiness.sh** - Production validator

## 🗂️ File Organization

```
/workspaces/hicko/
│
├── INTEGRATION SCRIPTS
│   ├── integrate.sh                  ← Run this!
│   ├── run_quick_integration.sh
│   └── stop-services.sh
│
├── DOCUMENTATION (This folder)
│   ├── START_INTEGRATION.md          ← Start here
│   ├── INTEGRATION.md
│   ├── INTEGRATION_TROUBLESHOOTING.md
│   ├── INTEGRATION_SYSTEM_OVERVIEW.txt
│   ├── SCRIPTS_CONSOLIDATED.md
│   ├── INTEGRATION_SETUP_COMPLETE.md
│   ├── INTEGRATION_FINAL_SUMMARY.txt
│   ├── READY_TO_TEST.md
│   └── INTEGRATION_DOCUMENTATION_INDEX.md (this file)
│
├── PROJECT FILES
│   ├── crates/control_api/           ← Rust backend
│   ├── web/ui/                       ← React frontend
│   ├── tests/                        ← Test suite
│   └── [other project files]
│
└── LOGS (created at runtime)
    └── /tmp/hickory-logs/            ← All service logs
```

## 📋 Quick Reference Card

```
START:              bash integrate.sh
QUICK MODE:         bash run_quick_integration.sh
STOP:               bash stop-services.sh
CHECK SYSTEM:       bash check_system.sh

ACCESS:             http://localhost:3000
LOGIN:              admin / admin123
API:                http://localhost:8080
DATABASE:           localhost:5432

VIEW LOGS:          tail -f /tmp/hickory-logs/*.log
STATUS:             ps aux | grep -E "(control_api|npm|postgres)"
HEALTH:             curl http://localhost:8080/health
```

## ⏱️ Time Estimates

| Task | First Run | Subsequent |
|------|-----------|-----------|
| Full integration | 10-15 min | 1-2 min |
| Quick mode | 2-5 min | 1-2 min |
| Prerequisites check | 30 sec | 30 sec |
| Services stop | 5 sec | 5 sec |

## 🎓 Learning Path

### Beginner
1. [START_INTEGRATION.md](START_INTEGRATION.md) - 5 min
2. Run `bash integrate.sh` - 10 min
3. Access http://localhost:3000 - 2 min

### Intermediate
1. [INTEGRATION.md](INTEGRATION.md) - 15 min
2. [INTEGRATION_SYSTEM_OVERVIEW.txt](INTEGRATION_SYSTEM_OVERVIEW.txt) - 10 min
3. Review `/web/ui/SETUP.md` - 5 min
4. Review `/crates/control_api/README.md` - 5 min

### Advanced
1. [INTEGRATION_TROUBLESHOOTING.md](INTEGRATION_TROUBLESHOOTING.md) - 15 min
2. [ARCHITECTURE.md](ARCHITECTURE.md) - 20 min
3. Review source code in `/crates/control_api/src/` - varies
4. Review UI code in `/web/ui/src/` - varies

## 🚀 Getting Started (TL;DR)

```bash
# 1. Run integration
bash integrate.sh

# 2. Wait for completion (10-15 minutes first run)
# Watch logs in another terminal:
tail -f /tmp/hickory-logs/api.log

# 3. Open browser
open http://localhost:3000

# 4. Login
Username: admin
Password: admin123

# 5. Use the application

# 6. When done, stop services
bash stop-services.sh
```

## ❓ FAQ

**Q: Where do I start?**
A: Read [START_INTEGRATION.md](START_INTEGRATION.md) and run `bash integrate.sh`

**Q: How long does setup take?**
A: 10-15 min first time, 1-2 min after that

**Q: What if something fails?**
A: Check [INTEGRATION_TROUBLESHOOTING.md](INTEGRATION_TROUBLESHOOTING.md)

**Q: How do I access the app?**
A: http://localhost:3000 → Username: admin, Password: admin123

**Q: Where are the logs?**
A: `/tmp/hickory-logs/*.log`

**Q: How do I stop services?**
A: `bash stop-services.sh` or press Ctrl+C

**Q: Can I start services separately?**
A: Yes, see [INTEGRATION_TROUBLESHOOTING.md](INTEGRATION_TROUBLESHOOTING.md) for manual startup

**Q: How do I run tests?**
A: After services start: `cd web/ui && npm run test:e2e`

**Q: What's different from before?**
A: See [SCRIPTS_CONSOLIDATED.md](SCRIPTS_CONSOLIDATED.md)

## 📞 Support

- **Quick answers:** Check [START_INTEGRATION.md](START_INTEGRATION.md)
- **Common issues:** Check [INTEGRATION_TROUBLESHOOTING.md](INTEGRATION_TROUBLESHOOTING.md)
- **Understanding architecture:** Check [INTEGRATION_SYSTEM_OVERVIEW.txt](INTEGRATION_SYSTEM_OVERVIEW.txt)
- **Complete guide:** Check [INTEGRATION.md](INTEGRATION.md)

---

**Ready?** Start with: `bash integrate.sh`

For quick start: Read [START_INTEGRATION.md](START_INTEGRATION.md)
