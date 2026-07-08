import { useState, useEffect, useCallback } from 'react';
import { api } from '../api';

export default function AjustesPage({ system, onSelectEmployee }) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const result = await api.ajustes(system, { page, per_page: 20, status_filter: statusFilter || undefined });
      setData(result);
    } catch (e) { console.error(e); }
    setLoading(false);
  }, [system, page, statusFilter]);

  useEffect(() => { load(); }, [load]);

  const formatDate = (d) => d ? new Date(d).toLocaleDateString('pt-BR') : '—';
  const formatDateTime = (d) => d ? new Date(d).toLocaleString('pt-BR') : '—';

  return (
    <>
      <div className="page-header">
        <h1>Solicitações de Ajuste de Ponto</h1>
        <p>Gerencie as solicitações de ajuste de batida de todos os funcionários</p>
      </div>

      <div className="card">
        <div className="toolbar">
          <select className="filter-select" value={statusFilter} onChange={e => { setStatusFilter(e.target.value); setPage(1); }}>
            <option value="">Todos Status</option>
            <option value="Pendente">Pendente</option>
            <option value="Aprovado">Aprovado</option>
            <option value="Reprovado">Reprovado</option>
          </select>
        </div>

        {loading ? (
          <div className="loading-wrapper"><div className="spinner"></div> Carregando...</div>
        ) : (
          <>
            <div className="table-wrapper">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Funcionário</th>
                    <th>Data Solicitação</th>
                    <th>Hora do Ajuste</th>
                    <th>Motivo</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {data?.items?.map(a => (
                    <tr key={a.id} className="clickable" onClick={() => onSelectEmployee(a.funcionario_id)}>
                      <td style={{ fontWeight: 600 }}>{a.funcionario_nome}</td>
                      <td>{formatDate(a.data_solicitacao)}</td>
                      <td>{formatDateTime(a.data_hora_ajuste)}</td>
                      <td>{a.motivo}</td>
                      <td>
                        <span className={`badge ${a.status === 'Aprovado' ? 'badge-success' : a.status === 'Pendente' ? 'badge-warning' : 'badge-danger'}`}>
                          {a.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                  {data?.items?.length === 0 && (
                    <tr><td colSpan="5" className="empty-state">Nenhuma solicitação encontrada</td></tr>
                  )}
                </tbody>
              </table>
            </div>
            {data && data.pages > 1 && (
              <div className="pagination">
                <div className="pagination-info">
                  Mostrando <strong>{(data.page - 1) * data.per_page + 1}</strong> – <strong>{Math.min(data.page * data.per_page, data.total)}</strong> de <strong>{data.total}</strong>
                </div>
                <div className="pagination-buttons">
                  <button className="pagination-btn" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>Anterior</button>
                  <button className="pagination-btn" disabled={page >= data.pages} onClick={() => setPage(p => p + 1)}>Próxima</button>
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </>
  );
}
