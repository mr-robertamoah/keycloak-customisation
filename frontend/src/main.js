import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import App from './App.vue'
import Home from './views/Home.vue'
import Blog from './views/Blog.vue'
import { initKeycloak, isAuthenticated } from './keycloak.js'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: Home },
    {
      path: '/blog',
      component: Blog,
      // Navigation guard — redirect to Keycloak login if not authenticated
      beforeEnter: (_to, _from, next) => {
        if (isAuthenticated()) {
          next()
        } else {
          // Import keycloak default export to trigger redirect
          import('./keycloak.js').then(({ default: kc }) => kc.login())
        }
      },
    },
  ],
})

// Initialise Keycloak before mounting the app
initKeycloak().then(() => {
  createApp(App).use(router).mount('#app')
})