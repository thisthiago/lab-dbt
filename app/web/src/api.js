const API = 'http://localhost:8000';

async function request(path, options = {}) {
  const res = await fetch(`${API}${path}`, options);
  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: 'Erro desconhecido' }));
    throw new Error(err.detail || `HTTP ${res.status}`);
  }
  return res.json();
}

export const api = {
  login: (username, password) =>
    request('/api/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password }),
    }),

  dashboard: (system) => request(`/api/${system}/dashboard`),

  funcionarios: (system, params = {}) => {
    const qs = new URLSearchParams();
    Object.entries(params).forEach(([k, v]) => { if (v != null && v !== '') qs.set(k, v); });
    return request(`/api/${system}/funcionarios?${qs}`);
  },

  funcionario: (system, id) => request(`/api/${system}/funcionarios/${id}`),

  apontamentos: (system, id, params = {}) => {
    const qs = new URLSearchParams();
    Object.entries(params).forEach(([k, v]) => { if (v != null && v !== '') qs.set(k, v); });
    return request(`/api/${system}/funcionarios/${id}/apontamentos?${qs}`);
  },

  ferias: (system, id) => request(`/api/${system}/funcionarios/${id}/ferias`),

  ajustesFuncionario: (system, id, params = {}) => {
    const qs = new URLSearchParams();
    Object.entries(params).forEach(([k, v]) => { if (v != null && v !== '') qs.set(k, v); });
    return request(`/api/${system}/funcionarios/${id}/ajustes?${qs}`);
  },

  ajustes: (system, params = {}) => {
    const qs = new URLSearchParams();
    Object.entries(params).forEach(([k, v]) => { if (v != null && v !== '') qs.set(k, v); });
    return request(`/api/${system}/ajustes?${qs}`);
  },

  feriasList: (system, params = {}) => {
    const qs = new URLSearchParams();
    Object.entries(params).forEach(([k, v]) => { if (v != null && v !== '') qs.set(k, v); });
    return request(`/api/${system}/ferias?${qs}`);
  },
};
