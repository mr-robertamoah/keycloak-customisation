<template>
  <div class="home">
    <h1>Welcome to The Blog</h1>
    <p>A demo application showcasing Keycloak customization with Vue and FastAPI.</p>
    
    <div class="features">
      <div class="feature">
        <h3>🔐 Custom Authentication</h3>
        <p>Fully customized Keycloak login and registration themes</p>
      </div>
      <div class="feature">
        <h3>✍️ Blog Platform</h3>
        <p>Create and manage your blog posts securely</p>
      </div>
      <div class="feature">
        <h3>🚀 Modern Stack</h3>
        <p>Vue 3, FastAPI, and Keycloak working together</p>
      </div>
    </div>

    <div class="cta">
      <router-link to="/blog" class="btn-primary">Get Started</router-link>
    </div>
  </div>
</template>

<style scoped>
.home {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
  text-align: center;
}

h1 {
  font-size: 3rem;
  margin-bottom: 1rem;
  color: #3B82F6;
}

.features {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 2rem;
  margin: 3rem 0;
}

.feature {
  padding: 2rem;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.feature h3 {
  margin-bottom: 1rem;
  font-size: 1.5rem;
}

.cta {
  margin-top: 3rem;
}

.btn-primary {
  display: inline-block;
  padding: 1rem 2rem;
  background: #3B82F6;
  color: white;
  text-decoration: none;
  border-radius: 6px;
  font-weight: 600;
  transition: background 0.2s;
}

.btn-primary:hover {
  background: #2563EB;
}
</style>
