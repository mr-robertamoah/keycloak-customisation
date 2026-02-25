<template>
  <div class="blog-page">
    <h1>My Posts</h1>

    <div v-if="loading" class="loading">Loading...</div>
    <div v-else-if="error" class="error">{{ error }}</div>

    <div v-else>
      <div class="post-form">
        <h2>New Post</h2>
        <input v-model="newPost.title" placeholder="Post title" class="form-input" />
        <textarea v-model="newPost.content" placeholder="Write something..." class="form-textarea" />
        <button @click="createPost" class="btn-primary">Publish</button>
      </div>

      <div class="posts">
        <div v-if="posts.length === 0" class="no-posts">
          <p>No posts yet. Create your first post above!</p>
        </div>
        <div v-for="post in posts" :key="post.id" class="post-card">
          <h3>{{ post.title }}</h3>
          <p>{{ post.content }}</p>
          <div class="post-meta">
            <small>By {{ post.author_name }}</small>
            <small>{{ formatDate(post.created_at) }}</small>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { getToken } from '../keycloak.js'

const posts = ref([])
const loading = ref(true)
const error = ref(null)
const newPost = ref({ title: '', content: '' })

async function apiFetch(url, options = {}) {
  const token = getToken()
  return fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
      ...options.headers,
    },
  })
}

onMounted(async () => {
  try {
    const res = await apiFetch('http://localhost:8001/api/users/me/posts')
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    posts.value = await res.json()
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
})

async function createPost() {
  if (!newPost.value.title || !newPost.value.content) {
    error.value = 'Please fill in both title and content'
    return
  }

  try {
    const res = await apiFetch('http://localhost:8002/api/posts', {
      method: 'POST',
      body: JSON.stringify({ ...newPost.value, published: true }),
    })
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const post = await res.json()
    posts.value.unshift(post)
    newPost.value = { title: '', content: '' }
    error.value = null
  } catch (e) {
    error.value = e.message
  }
}

function formatDate(dateStr) {
  return new Date(dateStr).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}
</script>

<style scoped>
.blog-page {
  max-width: 900px;
  margin: 0 auto;
}

h1 {
  font-size: 2.5rem;
  margin-bottom: 2rem;
  color: #1E293B;
}

.loading {
  text-align: center;
  padding: 3rem;
  color: #64748B;
}

.post-form {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  margin-bottom: 2rem;
}

.post-form h2 {
  margin-bottom: 1.5rem;
  color: #1E293B;
}

.form-input,
.form-textarea {
  width: 100%;
  padding: 0.75rem;
  border: 1.5px solid #E2E8F0;
  border-radius: 6px;
  font-size: 1rem;
  margin-bottom: 1rem;
  font-family: inherit;
  transition: border-color 0.2s;
}

.form-input:focus,
.form-textarea:focus {
  outline: none;
  border-color: #3B82F6;
}

.form-textarea {
  min-height: 120px;
  resize: vertical;
}

.posts {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.no-posts {
  text-align: center;
  padding: 3rem;
  background: white;
  border-radius: 8px;
  color: #64748B;
}

.post-card {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  transition: transform 0.2s, box-shadow 0.2s;
}

.post-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
}

.post-card h3 {
  margin-bottom: 1rem;
  color: #1E293B;
  font-size: 1.5rem;
}

.post-card p {
  color: #475569;
  line-height: 1.6;
  margin-bottom: 1rem;
}

.post-meta {
  display: flex;
  justify-content: space-between;
  padding-top: 1rem;
  border-top: 1px solid #E2E8F0;
  color: #64748B;
  font-size: 0.875rem;
}
</style>