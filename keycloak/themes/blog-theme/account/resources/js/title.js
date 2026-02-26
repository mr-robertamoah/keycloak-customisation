document.title = "The Blog - Account Management";

// Add back to blog button with retry logic
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
      font-size: 0.9rem;
      text-decoration: none;
      cursor: pointer;
    `;
    
    backLink.addEventListener('mouseover', () => backLink.style.background = '#DC2626');
    backLink.addEventListener('mouseout', () => backLink.style.background = '#EF4444');
    
    headerTools.insertBefore(backLink, headerTools.firstChild);
  }
}

// Try multiple times as React app loads
setTimeout(addBackLink, 100);
setTimeout(addBackLink, 500);
setTimeout(addBackLink, 1000);
