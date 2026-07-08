import { useState, useEffect, useCallback } from 'react';
import { api } from '../api';

export default function FeriasPage({ system, onSelectEmployee }) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const result = await api.feriasList(system, { page, per_page: 20 });
      setData(result);
    } catch (e) { console.error(e); }
    setLoading(false);
  }, [system, page]);

  useEffect(() => { load(); }, [load]);

  const formatDate = (d) => d ? new Date(d).toLocaleDateString('pt-BR') : '—';

  return (
    <>
      <div className="page-header">
        <h1>Registro de Férias</h1>
        <p>Consulte os períodos de férias de todos os funcionários</p>
      </div>

      <div className="card">
        {loading ? (
          <div className="loading-wrapper"><div className="spinner"></div> Carregando...</div>
        ) : (
          <>
            <div className="table-wrapper">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Funcionário</th>
                    <th>Data Início</th>
                    <th>Data Fim</th>
                    <th>Duração</th>
                  </tr>
                </thead>
                <tbody>
                  {data?.items?.map(f => {
                    const days = Math.round((new Date(f.data_fim) - new Date(f.data_inicio)) / 86400000);
                    return (
                      <tr key={f.id} className="clickable" onClick={() => onSelectEmployee(f.funcionario_id)}>
                        <td style={{ fontWeight: 600 }}>{f.funcionario_nome}</td>
                        <td>{formatDate(f.data_inicio)}</td>
                        <td>{formatDate(f.data_fim)}</td>
                        <td>{days} dias</td>
                      </tr>
                    );
                  })}
                  {data?.items?.length === 0 && (
                    <tr><td colSpan="4" className="empty-state">Nenhum registro encontrado</td></tr>
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
