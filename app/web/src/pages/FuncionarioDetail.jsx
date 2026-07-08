import { useState, useEffect } from 'react';
import { api } from '../api';

export default function FuncionarioDetail({ system, id, onBack }) {
  const [func, setFunc] = useState(null);
  const [tab, setTab] = useState('apontamentos');
  const [apontData, setApontData] = useState(null);
  const [apontPage, setApontPage] = useState(1);
  const [ferias, setFerias] = useState([]);
  const [ajustesData, setAjustesData] = useState(null);
  const [ajustesPage, setAjustesPage] = useState(1);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    Promise.all([
      api.funcionario(system, id),
      api.ferias(system, id),
    ]).then(([f, fer]) => {
      setFunc(f);
      setFerias(fer);
      setLoading(false);
    });
  }, [system, id]);

  useEffect(() => {
    if (tab === 'apontamentos') {
      api.apontamentos(system, id, { page: apontPage, per_page: 20 }).then(setApontData);
    }
  }, [system, id, tab, apontPage]);

  useEffect(() => {
    if (tab === 'ajustes') {
      api.ajustesFuncionario(system, id, { page: ajustesPage, per_page: 10 }).then(setAjustesData);
    }
  }, [system, id, tab, ajustesPage]);

  if (loading) return <div className="loading-wrapper"><div className="spinner"></div> Carregando...</div>;
  if (!func) return <div className="empty-state">Funcionário não encontrado.</div>;

  const initials = func.nome.split(' ').slice(0, 2).map(w => w[0]).join('').toUpperCase();
  const formatDate = (d) => d ? new Date(d).toLocaleDateString('pt-BR') : '—';
  const formatDateTime = (d) => d ? new Date(d).toLocaleString('pt-BR') : '—';
  const formatCurrency = (v) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(v);

  return (
    <>
      {/* Back + Header */}
      <button className="btn btn-ghost" onClick={onBack} style={{ marginBottom: '16px' }}>← Voltar para lista</button>

      <div className="profile-header">
        <div className="profile-avatar">{initials}</div>
        <div className="profile-info">
          <h1>{func.nome}</h1>
          <p className="profile-subtitle">
            {func.cargo} · {func.setor} · {func.empresa?.razao_social || ''}
          </p>
        </div>
        <span className={`badge ${func.status === 'Ativo' ? 'badge-success' : 'badge-danger'}`} style={{ fontSize: '13px', padding: '6px 14px' }}>
          {func.status}
        </span>
      </div>

      {/* Meta Cards */}
      <div className="profile-meta">
        <div className="profile-meta-item">
          <div className="meta-label">CPF</div>
          <div className="meta-value">{func.cpf}</div>
        </div>
        <div className="profile-meta-item">
          <div className="meta-label">Nascimento</div>
          <div className="meta-value">{formatDate(func.data_nascimento)}</div>
        </div>
        <div className="profile-meta-item">
          <div className="meta-label">Admissão</div>
          <div className="meta-value">{formatDate(func.data_admissao)}</div>
        </div>
        <div className="profile-meta-item">
          <div className="meta-label">Demissão</div>
          <div className="meta-value">{formatDate(func.data_demissao)}</div>
        </div>
        <div className="profile-meta-item">
          <div className="meta-label">Categoria</div>
          <div className="meta-value"><span className="badge badge-accent">{func.categoria}</span></div>
        </div>
        <div className="profile-meta-item">
          <div className="meta-label">Salário</div>
          <div className="meta-value">{formatCurrency(func.salario)}</div>
        </div>
      </div>

      {/* Tabs */}
      <div className="detail-tabs">
        <button className={`detail-tab ${tab === 'apontamentos' ? 'active' : ''}`} onClick={() => setTab('apontamentos')}>Apontamentos</button>
        <button className={`detail-tab ${tab === 'ferias' ? 'active' : ''}`} onClick={() => setTab('ferias')}>Férias ({ferias.length})</button>
        <button className={`detail-tab ${tab === 'ajustes' ? 'active' : ''}`} onClick={() => setTab('ajustes')}>Ajustes de Ponto</button>
      </div>

      {/* Tab Content */}
      {tab === 'apontamentos' && (
        <div className="card">
          <div className="card-header"><h3>Registro de Batidas</h3></div>
          {!apontData ? (
            <div className="loading-wrapper"><div className="spinner"></div></div>
          ) : (
            <>
              <div className="table-wrapper">
                <table className="data-table">
                  <thead><tr><th>Data e Hora</th><th>Tipo</th></tr></thead>
                  <tbody>
                    {apontData.items.map(a => (
                      <tr key={a.id}>
                        <td>{formatDateTime(a.data_hora)}</td>
                        <td><span className={`badge ${a.tipo === 'Entrada' ? 'badge-info' : 'badge-warning'}`}>{a.tipo}</span></td>
                      </tr>
                    ))}
                    {apontData.items.length === 0 && <tr><td colSpan="2" className="empty-state">Sem registros</td></tr>}
                  </tbody>
                </table>
              </div>
              {apontData.pages > 1 && (
                <div className="pagination">
                  <div className="pagination-info">Página {apontData.page} de {apontData.pages} ({apontData.total} registros)</div>
                  <div className="pagination-buttons">
                    <button className="pagination-btn" disabled={apontPage <= 1} onClick={() => setApontPage(p => p - 1)}>Anterior</button>
                    <button className="pagination-btn" disabled={apontPage >= apontData.pages} onClick={() => setApontPage(p => p + 1)}>Próxima</button>
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      )}

      {tab === 'ferias' && (
        <div className="card">
          <div className="card-header"><h3>Histórico de Férias</h3></div>
          <div className="table-wrapper">
            <table className="data-table">
              <thead><tr><th>Data Início</th><th>Data Fim</th><th>Duração</th></tr></thead>
              <tbody>
                {ferias.map(f => {
                  const days = Math.round((new Date(f.data_fim) - new Date(f.data_inicio)) / 86400000);
                  return (
                    <tr key={f.id}>
                      <td>{formatDate(f.data_inicio)}</td>
                      <td>{formatDate(f.data_fim)}</td>
                      <td>{days} dias</td>
                    </tr>
                  );
                })}
                {ferias.length === 0 && <tr><td colSpan="3" className="empty-state">Nenhum registro de férias</td></tr>}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {tab === 'ajustes' && (
        <div className="card">
          <div className="card-header"><h3>Solicitações de Ajuste</h3></div>
          {!ajustesData ? (
            <div className="loading-wrapper"><div className="spinner"></div></div>
          ) : (
            <>
              <div className="table-wrapper">
                <table className="data-table">
                  <thead><tr><th>Data Solicitação</th><th>Hora do Ajuste</th><th>Motivo</th><th>Status</th></tr></thead>
                  <tbody>
                    {ajustesData.items.map(a => (
                      <tr key={a.id}>
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
                    {ajustesData.items.length === 0 && <tr><td colSpan="4" className="empty-state">Sem solicitações</td></tr>}
                  </tbody>
                </table>
              </div>
              {ajustesData.pages > 1 && (
                <div className="pagination">
                  <div className="pagination-info">Página {ajustesData.page} de {ajustesData.pages}</div>
                  <div className="pagination-buttons">
                    <button className="pagination-btn" disabled={ajustesPage <= 1} onClick={() => setAjustesPage(p => p - 1)}>Anterior</button>
                    <button className="pagination-btn" disabled={ajustesPage >= ajustesData.pages} onClick={() => setAjustesPage(p => p + 1)}>Próxima</button>
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      )}
    </>
  );
}
