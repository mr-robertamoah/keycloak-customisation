// Auto-fill first and last name on registration form
document.addEventListener('DOMContentLoaded', () => {
  const form = document.getElementById('kc-register-form');
  if (form) {
    form.addEventListener('submit', (e) => {
      const firstName = document.getElementById('firstName');
      const lastName = document.getElementById('lastName');
      
      // Auto-fill with placeholder if empty
      if (firstName && !firstName.value) {
        firstName.value = 'User';
      }
      if (lastName && !lastName.value) {
        lastName.value = 'User';
      }
    });
  }
});
