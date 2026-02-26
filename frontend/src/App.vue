<template>
  <div id="app">
    <nav>
      <div class="nav-brand">The Blog</div>
      <div class="nav-links">
        <RouterLink to="/">Home</RouterLink>
        <RouterLink to="/blog" v-if="user">My Blog</RouterLink>
      </div>

      <div class="nav-right">
        <span v-if="user" class="user-greeting">Hi, {{ user.firstName || user.username }}</span>
        <a v-if="user" href="http://localhost:8080/realms/blog/account/" class="btn-link">Account</a>
        <button v-if="user" @click="handleLogout" class="btn-secondary">Logout</button>
        <button v-else @click="handleLogin" class="btn-primary">Login</button>
      </div>
    </nav>
    <main>
      <RouterView />
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { RouterLink, RouterView } from 'vue-router'
import { getUserInfo, login, logout } from './keycloak.js'

const user = ref(null)

onMounted(() => {
  user.value = getUserInfo()
})

function handleLogin() {
  login()
}

function handleLogout() {
  logout()
}
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
  background: #F8FAFF;
  color: #1E293B;
}

#app {
  min-height: 100vh;
}

nav {
  background: white;
  padding: 1rem 2rem;
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
  display: flex;
  align-items: center;
  gap: 2rem;
}

.nav-brand {
  font-size: 1.5rem;
  font-weight: 700;
  color: #3B82F6;
}

.nav-links {
  display: flex;
  gap: 1.5rem;
  flex: 1;
}

.nav-links a {
  text-decoration: none;
  color: #64748B;
  font-weight: 500;
  transition: color 0.2s;
}

.nav-links a:hover,
.nav-links a.router-link-active {
  color: #3B82F6;
}

.nav-right {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.user-greeting {
  color: #64748B;
  font-size: 0.9rem;
}

button, .btn-link {
  padding: 0.5rem 1.25rem;
  border: none;
  border-radius: 6px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 0.9rem;
  text-decoration: none;
  display: inline-block;
}

.btn-link {
  background: #EF4444;
  color: white;
}

.btn-link:hover {
  background: #DC2626;
}

.btn-primary {
  background: #3B82F6;
  color: white;
}

.btn-primary:hover {
  background: #2563EB;
}

.btn-secondary {
  background: #F1F5F9;
  color: #475569;
}

.btn-secondary:hover {
  background: #E2E8F0;
}

main {
  padding: 2rem;
}

.error {
  background: #FEF2F2;
  color: #B91C1C;
  padding: 1rem;
  border-radius: 6px;
  border: 1px solid #FECACA;
  margin: 1rem 0;
}
</style>