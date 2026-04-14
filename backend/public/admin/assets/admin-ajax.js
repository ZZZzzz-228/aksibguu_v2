/**
 * AJAX помощник для администратору панели
 * Обеспечивает асинхронные запросы для некритичных действий
 */

const AdminAjax = (() => {
  //获取CSRF токен из meta тага
  function getCsrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.getAttribute('content') : '';
  }

  async function post(url, data = {}) {
    const csrfToken = getCsrfToken();
    const formData = new FormData();
    
    // Добавляем CSRF токен (ключ _csrf для совместимости с системой)
    if (csrfToken) {
      formData.append('_csrf', csrfToken);
    }

    // Добавляем все данные
    for (const [key, value] of Object.entries(data)) {
      formData.append(key, value);
    }

    try {
      const response = await fetch(url, {
        method: 'POST',
        body: formData,
        headers: {
          'X-Requested-With': 'XMLHttpRequest'
        },
        // Включаем cookies для авторизации
        credentials: 'same-origin'
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const result = await response.json();
      return result;
    } catch (error) {
      console.error('AJAX Error:', error);
      throw error;
    }
  }

  /**
   * Toggle publish статус элемента
   * @param {string} url - URL страницы (например /admin/staff.php)
   * @param {number} id - ID элемента
   * @param {string} entityType - Тип сущности для логирования
   */
  async function togglePublish(url, id, entityType = 'item') {
    try {
      const result = await post(url, {
        action: 'toggle_publish',
        id: id
      });

      if (result.success) {
        Toast.success(`${entityType} теперь ${result.is_published ? 'опубликован' : 'скрыт'}`);
        return { success: true, is_published: result.is_published };
      } else {
        Toast.error(result.message || 'Ошибка при обновлении');
        return { success: false };
      }
    } catch (error) {
      Toast.error('Ошибка при обновлении статуса');
      return { success: false };
    }
  }

  /**
   * Изменить порядок элемента (вверх/вниз)
   */
  async function moveItem(url, id, direction) {
    const action = direction === 'up' ? 'move_up' : 'move_down';
    try {
      const result = await post(url, {
        action: action,
        id: id
      });

      if (result.success) {
        Toast.success(direction === 'up' ? 'Переместено выше' : 'Переместено ниже');
        return { success: true };
      } else {
        Toast.error(result.message || 'Ошибка при перемещении');
        return { success: false };
      }
    } catch (error) {
      Toast.error('Ошибка при перемещении');
      return { success: false };
    }
  }

  /**
   * Удалить элемент с подтверждением
   */
  async function deleteItem(url, id, entityType = 'элемент') {
    if (!confirm(`Вы уверены, что хотите удалить ${entityType}?`)) {
      return { success: false };
    }

    try {
      const result = await post(url, {
        action: 'delete',
        id: id
      });

      if (result.success) {
        Toast.success(`${entityType} удален`);
        return { success: true };
      } else {
        Toast.error(result.message || 'Ошибка при удалении');
        return { success: false };
      }
    } catch (error) {
      Toast.error('Ошибка при удалении');
      return { success: false };
    }
  }

  return {
    post,
    togglePublish,
    moveItem,
    deleteItem
  };
})();
