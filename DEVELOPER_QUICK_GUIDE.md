# Quick Developer Guide - Hickory DNS Manager UI

## 🎬 Getting Started (5 minutes)

### 1. Terminal 1 - Start Services
```bash
cd /workspaces/hicko
bash start_integration_test.sh
```

### 2. Terminal 2 - Access Application
```bash
# Wait for services to start (2-3 min), then open:
# http://localhost:3000
# 
# Login: admin / admin123
# 
# Logs: /tmp/hickory-logs/
```

## 📂 Project Structure

```
web/ui/src/
├── pages/               # Page components
│   ├── Login.jsx       # Authentication
│   ├── Admin.jsx       # Admin layout
│   ├── User.jsx        # User dashboard
│   └── Admin/          # Admin pages
│       ├── Dashboard.jsx
│       ├── Zones.jsx
│       ├── Records.jsx
│       ├── Users.jsx
│       ├── Servers.jsx
│       ├── GeoRules.jsx
│       └── AuditLogs.jsx
├── components/         # Reusable components
│   ├── Layout.jsx      # Header & nav
│   ├── Modal.jsx
│   ├── Notifications.jsx
│   ├── BulkImport.jsx
│   └── FormField.jsx
├── hooks/              # Custom React hooks
│   ├── useFormValidation.js  # Form state
│   └── useAdvancedUI.js      # Pagination, sorting
├── contexts/           # React context
│   ├── AuthContext.jsx
│   └── NotificationsContext.jsx
├── api.js              # Axios wrapper
└── main.jsx            # Entry point
```

## 🔧 Common Tasks

### Add New Page/Component
```bash
# Create component file
touch web/ui/src/components/MyComponent.jsx

# Export from page
import MyComponent from '../../components/MyComponent'

# Use with error handling
const [data, setData] = React.useState([])
try {
  const res = await api.get('/api/v1/endpoint')
  setData(res.data)
} catch (e) {
  notify?.error('Failed to load data')
}
```

### Add API Endpoint Integration
```bash
# In your component
import api from '../../api'
import { useContext } from 'react'
import Notifications from '../../components/Notifications'

const MyComponent = () => {
  const notify = useContext(Notifications)
  
  const loadData = async () => {
    try {
      const res = await api.get('/api/v1/zones')
      // Process response
    } catch (error) {
      notify?.error('API Error: ' + error.message)
    }
  }
}
```

### Add Form with Validation
```bash
import { useFormValidation, validators, FormField } from '../../hooks/useFormValidation'

const { values, errors, bind, validate, reset } = useFormValidation(
  { email: '', domain: '' },
  (vals) => ({
    email: validators.email(vals.email),
    domain: validators.domain(vals.domain)
  })
)

// In JSX:
<FormField label="Email" error={errors.email}>
  <input {...bind('email')} />
</FormField>
```

### Add Table with Pagination & Sorting
```bash
import { usePagination, useTableSort, SortableHeader, PaginationControls } from '../../hooks/useAdvancedUI'

const { sortedItems, sortConfig, requestSort } = useTableSort(items)
const pagination = usePagination(sortedItems, 10)

// In JSX:
<SortableHeader field="name" label="Name" sortConfig={sortConfig} onSort={requestSort} />
<PaginationControls pagination={pagination} />
```

### Add Search Feature
```bash
import { useAdvancedSearch } from '../../hooks/useAdvancedUI'

const { searchTerm, filteredItems, handleSearch } = useAdvancedSearch(
  items,
  ['domain', 'id', 'email']  // searchable fields
)

// In JSX:
<input
  value={searchTerm}
  onChange={(e) => handleSearch(e.target.value)}
  placeholder="Search..."
/>
```

### Add Dark Mode Support
```bash
// Automatically applied to all Tailwind components with `dark:` prefix
<div className="bg-white dark:bg-gray-800 text-black dark:text-white">
  Content
</div>

// Dark mode toggle built into Layout.jsx
// Stored in localStorage automatically
```

### Show Notification
```bash
const notify = useContext(Notifications)

notify?.success('Operation completed')
notify?.error('Something went wrong')
notify?.info('FYI: This is information')
notify?.warning('Be careful!')
```

### Add Animation
```bash
import { FadeIn, SlideIn, BounceIn } from '../../hooks/useAdvancedUI'

<FadeIn duration={300}>
  <div>Fades in smoothly</div>
</FadeIn>

<SlideIn direction="left" duration={300}>
  <div>Slides in from left</div>
</SlideIn>

<BounceIn duration={400}>
  <div>Bounces in with spring effect</div>
</BounceIn>
```

## 📡 API Integration Guide

### Available API Endpoints

**Authentication**
```javascript
POST /api/v1/auth/login
// body: { username, password }
// response: { token, user: { id, username } }
```

**Zones**
```javascript
GET /api/v1/zones                 // List all
POST /api/v1/zones                // Create { domain }
GET /api/v1/zones/{id}            // Get one
DELETE /api/v1/zones/{id}         // Delete
POST /api/v1/zones/bulk           // Bulk import
```

**Records**
```javascript
GET /api/v1/zones/{id}/records    // List
POST /api/v1/zones/{id}/records   // Create
PUT /api/v1/zones/{id}/records/{id} // Update
DELETE /api/v1/zones/{id}/records/{id} // Delete
POST /api/v1/zones/{id}/records/bulk  // Bulk import
```

**Users** (Admin only)
```javascript
GET /api/v1/users
POST /api/v1/users                // { username, password }
DELETE /api/v1/users/{id}
```

**Servers**
```javascript
GET /api/v1/servers
POST /api/v1/servers
GET /api/v1/admin/stats
```

**GeoRules**
```javascript
GET /api/v1/georules
POST /api/v1/georules
DELETE /api/v1/georules/{id}
```

**Audit**
```javascript
GET /api/v1/audit                 // Get audit logs
```

## 🧪 Testing

### Run E2E Tests
```bash
cd web/ui
npx playwright test              # All tests
npx playwright test --headed     # With browser
npx playwright test --debug      # Step through
```

### Write New E2E Test
```javascript
import { test, expect } from '@playwright/test'

test('my test', async ({ page, context }) => {
  // Login
  await page.goto('http://localhost:3000/login')
  await page.fill('input[name=username]', 'admin')
  await page.fill('input[name=password]', 'admin123')
  await page.click('button:has-text("Login")')
  
  // Wait for redirect
  await page.waitForURL('http://localhost:3000/admin')
  
  // Assert
  expect(page.url()).toContain('/admin')
})
```

### Check Backend
```bash
# Test all API endpoints
bash check_backend_connectivity.sh

# Check production readiness
bash verify_production_readiness.sh
```

## 🐛 Debugging

### Frontend Issues
```bash
# 1. Check browser console (F12)
# 2. Check UI logs:
tail -f /tmp/hickory-logs/ui.log

# 3. Clear cache and rebuild:
cd web/ui
rm -rf node_modules package-lock.json
npm install
npm run dev
```

### Backend Issues
```bash
# 1. Check API logs:
tail -f /tmp/hickory-logs/api.log

# 2. Test API directly:
curl http://localhost:8080/health
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# 3. Check database:
docker exec hickory-postgres psql -U postgres -d hickory -c "SELECT * FROM users;"
```

### Database Issues
```bash
# Connect to database
docker exec -it hickory-postgres psql -U postgres -d hickory

# View schema
\dt

# Query specific table
SELECT * FROM zones;
```

## 🚀 Performance Tips

1. **Use React.memo for expensive components**
   ```javascript
   const MyComponent = React.memo(({ data }) => (...))
   ```

2. **Lazy load pages**
   ```javascript
   const AdminPage = lazy(() => import('./pages/Admin'))
   ```

3. **Debounce search input**
   ```javascript
   const [searchTimeout, setSearchTimeout] = useState(null)
   const handleSearch = (term) => {
     clearTimeout(searchTimeout)
     const timeout = setTimeout(() => setSearchTerm(term), 300)
     setSearchTimeout(timeout)
   }
   ```

4. **Paginate large datasets**
   ```javascript
   const { currentItems } = usePagination(allItems, 10)
   // render currentItems instead of allItems
   ```

5. **Cache API responses**
   ```javascript
   const [cache, setCache] = useState({})
   const getCached = async (url) => {
     if (cache[url]) return cache[url]
     const res = await api.get(url)
     setCache(prev => ({ ...prev, [url]: res.data }))
     return res.data
   }
   ```

## 📝 Code Style Guide

### File Naming
- Pages: PascalCase (Login.jsx, Dashboard.jsx)
- Components: PascalCase (Modal.jsx, FormField.jsx)
- Hooks: camelCase (useFormValidation.js, usePagination.js)
- Utilities: camelCase (api.js, validators.js)

### Component Structure
```javascript
import React from 'react'
import { useContext } from 'react'
import api from '../../api'
import Notifications from '../../components/Notifications'

export default function MyComponent() {
  // 1. State
  const [data, setData] = React.useState([])
  const notify = useContext(Notifications)
  
  // 2. Effects
  React.useEffect(() => {
    loadData()
  }, [])
  
  // 3. Event handlers
  const loadData = async () => { ... }
  const handleCreate = async () => { ... }
  
  // 4. Render
  return (
    <div className="...">
      {/* JSX here */}
    </div>
  )
}
```

## 🔗 Useful Links

- [React Hooks](https://react.dev/reference/react)
- [Tailwind CSS Classes](https://tailwindcss.com/docs/installation)
- [Axios Documentation](https://axios-http.com/)
- [Playwright Testing](https://playwright.dev/docs/intro)
- [Vite Documentation](https://vitejs.dev/)

## 💡 Pro Tips

1. **Set token on mount**
   ```javascript
   React.useEffect(() => {
     const token = localStorage.getItem('token')
     if (token) api.setToken(token)
   }, [])
   ```

2. **Use async/await instead of .then()**
   ```javascript
   // Good
   const data = await api.get('/endpoint')
   
   // Avoid
   api.get('/endpoint').then(res => ...)
   ```

3. **Always handle errors gracefully**
   ```javascript
   try {
     // operation
   } catch (error) {
     notify?.error(error.response?.data?.message || 'Operation failed')
   }
   ```

4. **Use context for global state**
   ```javascript
   // Good - centralized auth state
   const { user, login, logout } = useContext(AuthContext)
   
   // Avoid - prop drilling
   <Component user={user} setUser={setUser} ... />
   ```

5. **Validate early**
   ```javascript
   if (!validate()) return  // Stop if validation fails
   // ... rest of function
   ```

---

**For complete documentation**, see [PRODUCTION_READY_SUMMARY.md](./PRODUCTION_READY_SUMMARY.md)

**Questions?** Check the logs in `/tmp/hickory-logs/`
