const API = '/api';

const statusLabel = {
  REQUESTED: '예약신청됨',
  PAID: '결제됨',
  CONFIRMED: '예약확정됨',
  CANCELLED: '예약취소됨',
  REFUNDED: '환불됨'
};

const paymentTypeLabel = {
  PAYMENT: '결제',
  REFUND: '환불'
};

function showToast(message, isError = false) {
  const toast = document.getElementById('toast');
  toast.textContent = message;
  toast.style.background = isError ? '#b91c1c' : '#111827';
  toast.classList.remove('hidden');
  setTimeout(() => toast.classList.add('hidden'), 3000);
}

async function request(url, options = {}) {
  const response = await fetch(url, {
    headers: { 'Content-Type': 'application/json' },
    ...options
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(text || '요청 처리 중 오류가 발생했습니다.');
  }

  if (response.status === 204) {
    return null;
  }

  return response.json();
}

async function loadRooms() {
  const rooms = await request(`${API}/rooms`);
  const container = document.getElementById('room-list');
  container.innerHTML = rooms.map(room => `
    <article class="room-card">
      <h3>${room.roomName}</h3>
      <p>객실 ID: ${room.roomId}</p>
      <p>재고: ${room.stockCount}개</p>
      <p>기준일: ${room.invDate}</p>
    </article>
  `).join('');
}

async function loadReservations() {
  const reservations = await request(`${API}/reservations`);
  const tbody = document.getElementById('reservation-table');
  tbody.innerHTML = reservations.map(item => `
    <tr>
      <td>${item.id}</td>
      <td>${item.roomId}</td>
      <td>${item.userId}</td>
      <td>${Number(item.price).toLocaleString()}원</td>
      <td><span class="status ${item.status}">${statusLabel[item.status] || item.status}</span></td>
      <td>${item.checkInDate}</td>
      <td>${item.checkOutDate}</td>
      <td>
        <div class="actions">
          ${item.status === 'REQUESTED' ? `<button class="btn success" data-action="pay" data-id="${item.id}">금액지불</button>` : ''}
          ${item.status === 'PAID' ? `<button class="btn primary" data-action="approve" data-id="${item.id}">예약승인</button>` : ''}
          ${item.status === 'PAID' || item.status === 'CONFIRMED' ? `<button class="btn warning" data-action="refund" data-id="${item.id}">금액환불</button>` : ''}
          ${item.status !== 'CANCELLED' && item.status !== 'REFUNDED'
            ? `<button class="btn danger" data-action="cancel" data-id="${item.id}">예약취소</button>`
            : ''}
        </div>
      </td>
    </tr>
  `).join('');
}

async function loadPayments() {
  const payments = await request(`${API}/payments`);
  const tbody = document.getElementById('payment-table');
  tbody.innerHTML = payments.map(item => `
    <tr>
      <td>${item.id}</td>
      <td>${item.reservationId}</td>
      <td>${Number(item.price).toLocaleString()}원</td>
      <td>${paymentTypeLabel[item.type] || item.type}</td>
    </tr>
  `).join('');
}

async function refreshAll() {
  await Promise.all([loadRooms(), loadReservations(), loadPayments()]);
}

document.getElementById('reserve-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  const formData = new FormData(event.target);
  const payload = Object.fromEntries(formData.entries());
  payload.roomId = Number(payload.roomId);
  payload.price = Number(payload.price);

  try {
    await request(`${API}/reservations`, {
      method: 'POST',
      body: JSON.stringify(payload)
    });
    event.target.reset();
    showToast('숙소 예약이 완료되었습니다.');
    await refreshAll();
  } catch (error) {
    showToast(error.message, true);
  }
});

document.getElementById('reservation-table').addEventListener('click', async (event) => {
  const button = event.target.closest('button[data-action]');
  if (!button) {
    return;
  }

  const action = button.dataset.action;
  const id = button.dataset.id;

  try {
    await request(`${API}/reservations/${id}/${action}`, { method: 'POST' });
    showToast('처리되었습니다.');
    await refreshAll();
  } catch (error) {
    showToast(error.message, true);
  }
});

refreshAll().catch(error => showToast(error.message, true));
