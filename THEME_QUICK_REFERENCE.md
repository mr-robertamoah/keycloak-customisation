# Theme Customization - Quick Reference

## What Was Fixed

### Issues Encountered:
1. ❌ Theme changes not appearing
2. ❌ Custom login.ftl template ignored
3. ❌ Blue colors persisting despite CSS changes
4. ❌ Emoji and custom title not showing

### Root Causes:
1. **Missing file reference** - `theme.properties` referenced `css/login.css` which didn't exist
2. **Parent theme override** - Parent's template.ftl was being used instead of custom one
3. **CSS specificity** - Parent's PatternFly CSS had higher specificity
4. **Browser caching** - Old CSS was cached

### Solutions Applied:
1. ✅ Fixed `theme.properties` to only reference existing files
2. ✅ Used CSS overrides with `!important` instead of custom templates
3. ✅ Created missing `logo.svg` file
4. ✅ Added CSS content injection with `::before` and `::after`
5. ✅ Overrode PatternFly v5 CSS variables for account console

---

## Final Working Configuration

### Login Theme Structure
```
login/
├── theme.properties              # parent=keycloak, styles=css/styles.css, scripts=js/register.js
├── messages/
│   └── messages_en.properties   # loginTitle=Sign in to The Blog
├── resources/
│   ├── css/styles.css           # CSS overrides with !important
│   ├── js/
│   │   └── register.js          # Auto-fill first/last name on registration
│   └── img/
│       ├── logo.svg             # Custom logo displayed in header
│       └── favicon.ico          # Browser tab icon
└── templates/
    ├── login.ftl
    ├── register.ftl
    └── error.ftl
```

### Account Theme Structure
```
account/
├── theme.properties              # parent=keycloak.v3, styles=css/styles.css, scripts=js/title.js
├── messages/
│   └── messages_en.properties   # (Not used by React SPA)
└── resources/
    ├── favicon.svg              # Must be at resources root for React app
    ├── css/styles.css           # PatternFly v5 overrides
    ├── js/
    │   └── title.js             # document.title = "The Blog - Account Management"
    └── img/
        ├── logo.svg             # Header logo (40x40)
        ├── favicon.svg          # Copy of favicon
        └── favicon.ico          # Fallback
```

**Key differences:**
- Login: Favicon in `img/favicon.ico`, title via messages properties
- Account: Favicon at `resources/favicon.svg`, title via JavaScript (React SPA)

### Key CSS Techniques Used

**1. Hide parent elements:**
```css
#kc-header-wrapper { display: none !important; }
#kc-page-title { display: none !important; }
```

**2. Inject custom content:**
```css
#kc-header::before {
  content: "🚀 The Blog";
  display: block;
  text-align: center;
  font-size: 1.5rem;
  font-weight: 700;
}
```

**3. Override colors:**
```css
.pf-c-button.pf-m-primary {
  background-color: #EF4444 !important;
}

a {
  color: #EF4444 !important;
}
```

**4. Change background:**
```css
body, .login-pf-page {
  background: #FEE2E2 !important;
}
```

**5. Improve registration form:**
```css
/* Hide first/last name fields */
#kc-register-form .form-group:has(input[name="firstName"]),
#kc-register-form .form-group:has(input[name="lastName"]) {
  display: none !important;
}

/* Add scrolling for long forms */
#kc-container {
  max-height: 90vh;
  overflow-y: auto;
}

/* Keep required asterisk inline */
.pf-c-form__label-required {
  display: inline !important;
  margin-left: 0.25rem;
}
```

**JavaScript to auto-fill hidden fields (login/resources/js/register.js):**
```javascript
document.addEventListener('DOMContentLoaded', () => {
  const form = document.getElementById('kc-register-form');
  if (form) {
    form.addEventListener('submit', () => {
      const firstName = document.getElementById('firstName');
      const lastName = document.getElementById('lastName');
      if (firstName && !firstName.value) firstName.value = 'User';
      if (lastName && !lastName.value) lastName.value = 'User';
    });
  }
});
```

**Update theme.properties:**
```properties
scripts=js/register.js
```

### Account Theme

```css
/* Override PatternFly v5 variables */
:root {
  --pf-v5-global--primary-color--100: #EF4444 !important;
  --pf-v5-c-button--m-primary--BackgroundColor: #EF4444 !important;
  --pf-v5-global--BackgroundColor--100: #FEE2E2 !important;
}

/* Style specific components */
body, .pf-c-page, .pf-c-page__header, .pf-c-page__sidebar, .pf-c-nav {
  background: #FEE2E2 !important;
}

/* Fix text colors */
.pf-c-button.pf-m-plain,
.pf-c-nav__link {
  color: #1E293B !important;
}

/* Show logo in header */
.pf-c-page__header-brand-link img {
  content: url('../img/logo.svg') !important;
  display: inline-block !important;
  width: 40px !important;
  height: 40px !important;
  margin-right: 0.5rem !important;
}

.pf-c-page__header-brand-link::after {
  content: "The Blog";
  font-size: 1.3rem;
  font-weight: 700;
  color: #1E293B;
}

/* Add subtitle */
.pf-c-page__main::before {
  content: "Manage your account settings";
  display: block;
  text-align: center;
  color: #64748B;
  font-size: 0.9rem;
  padding: 1rem 0;
  background: #FEE2E2;
}
```

**JavaScript for tab title (account/resources/js/title.js):**
```javascript
document.title = "The Blog - Account Management";
```

**theme.properties:**
```properties
parent=keycloak.v3
styles=css/styles.css
scripts=js/title.js
```

**Important:** 
- Favicon must be at `account/resources/favicon.svg` (React app looks there)
- Tab title requires JavaScript since React SPA sets it dynamically
- Messages properties don't work for account console title

### Email Theme

Email templates use inline styles (no external CSS):

```html
<style>
  .email-header { background: #EF4444; }
  .btn { background: #EF4444; color: #fff; }
</style>

<div class="email-header">
  <h1>🚀 The Blog</h1>
</div>
```

---

## The Learning Path

### What You Discovered:

1. **Theme inheritance is powerful but tricky**
   - Parent themes provide functionality
   - But they can override your customizations
   - CSS overrides are often simpler than template overrides

2. **File references must be exact**
   - One missing file = entire theme fails silently
   - Always verify files exist in the container

3. **CSS specificity matters**
   - Parent themes use specific selectors
   - Use `!important` to override
   - Or use more specific selectors

4. **Different themes need different approaches**
   - Login: Override PatternFly v4 classes
   - Account: Override PatternFly v5 CSS variables
   - Email: Inline styles only

5. **Browser caching is aggressive**
   - Always hard refresh (Ctrl+Shift+R)
   - Use incognito mode for testing
   - Even with cache disabled in Keycloak

---

## Commands Reference

### Customize tab titles:
```bash
# Login page - use messages properties
echo "loginTitle=Sign in to The Blog" > keycloak/themes/blog-theme/login/messages/messages_en.properties

# Account page - use JavaScript
echo 'document.title = "The Blog - Account Management";' > keycloak/themes/blog-theme/account/resources/js/title.js

# Add script to account theme.properties
# scripts=js/title.js
```

### Customize favicons:
```bash
# Login page - place in img/ folder
cp your-icon.svg keycloak/themes/blog-theme/login/resources/img/favicon.ico

# Account page - must be at resources root
cp your-icon.svg keycloak/themes/blog-theme/account/resources/favicon.svg
```

### Check theme is loaded:
```bash
docker compose exec keycloak /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password admin
docker compose exec keycloak /opt/keycloak/bin/kcadm.sh get realms/blog --fields loginTheme,accountTheme,emailTheme
```

### Force theme update:
```bash
docker compose exec keycloak /opt/keycloak/bin/kcadm.sh update realms/blog -s loginTheme=blog-theme -s accountTheme=blog-theme -s emailTheme=blog-theme
```

### Verify files in container:
```bash
docker compose exec keycloak ls -la /opt/keycloak/themes/blog-theme/login/resources/css/
docker compose exec keycloak cat /opt/keycloak/themes/blog-theme/login/theme.properties
```

### Check for errors:
```bash
docker compose logs keycloak | grep -i error
```

---

## Best Practices

1. **Start with CSS overrides** - Simpler than template changes
2. **Test in incognito mode** - Avoids cache issues
3. **Verify file references** - Check theme.properties matches actual files
4. **Use !important sparingly** - But necessary for parent theme overrides
5. **Keep parent theme** - Unless you need complete control
6. **Check container files** - Volume mounts can have sync issues

---

## Next Steps

Now that you understand theme customization, you can:
- Customize other pages (register.ftl, error.ftl, etc.)
- Add custom JavaScript for interactivity
- Create completely custom themes without parent
- Brand email templates with your company colors
- Customize the admin console theme

---

## Navigation Between Frontend and Account

### Frontend → Account Page
Add a link in your frontend navigation:

**App.vue:**
```vue
<a v-if="user" href="http://localhost:8080/realms/blog/account/" class="btn-link">Account</a>
```

**CSS:**
```css
.btn-link {
  background: #EF4444;
  color: white;
  padding: 0.5rem 1.25rem;
  border-radius: 6px;
  text-decoration: none;
}
```

### Account Page → Frontend
Inject a clickable link via JavaScript (account/resources/js/title.js):

```javascript
function addBackLink() {
  const headerTools = document.querySelector('.pf-c-page__header-tools');
  if (headerTools && !document.querySelector('.back-to-blog-link')) {
    const backLink = document.createElement('a');
    backLink.href = 'http://localhost:5173';
    backLink.textContent = '← Back to Blog';
    backLink.className = 'back-to-blog-link';
    backLink.style.cssText = `
      display: inline-block;
      margin-right: 1.5rem;
      padding: 0.5rem 1rem;
      background: #EF4444;
      color: white !important;
      border-radius: 6px;
      font-weight: 600;
      cursor: pointer;
    `;
    headerTools.insertBefore(backLink, headerTools.firstChild);
  }
}

// Retry as React app loads
setTimeout(addBackLink, 100);
setTimeout(addBackLink, 500);
setTimeout(addBackLink, 1000);
```

**Why JavaScript?** The account console is a React SPA, so you can't use static HTML. JavaScript dynamically injects the link after the app loads.
