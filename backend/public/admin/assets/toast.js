/**
 * Toast уведомления для админ панели
 * Использование: Toast.show('Сообщение', 'success', 3000);
 */

const Toast = (() => {
  const toastContainer = document.getElementById('toastContainer') || createToastContainer();

  function createToastContainer() {
    const container = document.createElement('div');
    container.id = 'toastContainer';
    container.style.cssText = `
      position: fixed;
      bottom: 20px;
      right: 20px;
      z-index: 9999;
      display: flex;
      flex-direction: column;
      gap: 10px;
      max-width: 400px;
      pointer-events: none;
    `;
    document.body.appendChild(container);
    return container;
  }

  function show(message, type = 'info', duration = 3000) {
    const toast = document.createElement('div');
    const bgColor = {
      'success': '#10b981',
      'error': '#ef4444',
      'info': '#3b82f6',
      'warning': '#f59e0b'
    }[type] || '#3b82f6';

    const icon = {
      'success': '✓',
      'error': '✕',
      'info': 'ⓘ',
      'warning': '⚠'
    }[type] || 'ⓘ';

    toast.style.cssText = `
      background: ${bgColor};
      color: white;
      padding: 14px 16px;
      border-radius: 8px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
      display: flex;
      align-items: center;
      gap: 10px;
      animation: toastSlideIn 0.3s ease-out;
      pointer-events: auto;
      cursor: pointer;
      font-size: 14px;
      font-weight: 500;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      min-width: 200px;
    `;

    toast.innerHTML = `
      <span style="font-size: 18px; line-height: 1;">${icon}</span>
      <span>${message}</span>
    `;

    // Добавляем стили анимации, если их нет
    if (!document.getElementById('toastStyles')) {
      const style = document.createElement('style');
      style.id = 'toastStyles';
      style.textContent = `
        @keyframes toastSlideIn {
          from {
            transform: translateX(400px);
            opacity: 0;
          }
          to {
            transform: translateX(0);
            opacity: 1;
          }
        }
        @keyframes toastSlideOut {
          from {
            transform: translateX(0);
            opacity: 1;
          }
          to {
            transform: translateX(400px);
            opacity: 0;
          }
        }
      `;
      document.head.appendChild(style);
    }

    toastContainer.appendChild(toast);

    // Удаление при клике
    toast.addEventListener('click', () => removeToast(toast));

    // Автоматическое удаление
    if (duration > 0) {
      const timeout = setTimeout(() => removeToast(toast), duration);
      toast.addEventListener('mouseenter', () => clearTimeout(timeout));
    }

    return toast;
  }

  function removeToast(toast) {
    toast.style.animation = 'toastSlideOut 0.3s ease-out forwards';
    setTimeout(() => toast.remove(), 300);
  }

  return {
    show,
    success: (msg, duration) => show(msg, 'success', duration),
    error: (msg, duration) => show(msg, 'error', duration),
    info: (msg, duration) => show(msg, 'info', duration),
    warning: (msg, duration) => show(msg, 'warning', duration)
  };
})();

// Экспорт для использования в других скриптах
if (typeof module !== 'undefined' && module.exports) {
  module.exports = Toast;
}
