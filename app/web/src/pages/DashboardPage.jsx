export default function DashboardPage({ data }) {
  if (!data) return <div className="loading-wrapper"><div className="spinner"></div> Carregando painel...</div>;

  const maxAdm = Math.max(...data.admissoes_por_ano.map(a => a.total), 1);
  const maxSetor = Math.max(...data.por_setor.map(s => s.total), 1);

  return (
    <>
      <div className="page-header">
        <h1>Painel Geral</h1>
        <p>Visão consolidada dos indicadores do sistema de ponto eletrônico</p>
      </div>

      {/* KPI Cards */}
      <div className="kpi-grid">
        <div className="kpi-card">
          <div className="kpi-icon" style={{ background: 'var(--accent-muted)', color: 'var(--accent-hover)' }}>👥</div>
          <div className="kpi-label">Total de Funcionários</div>
          <div className="kpi-value">{data.total_funcionarios}</div>
          <div className="kpi-sub">{data.empresas.length} empresa(s) no grupo</div>
        </div>
        <div className="kpi-card">
          <div className="kpi-icon" style={{ background: 'var(--success-muted)', color: 'var(--success)' }}>✓</div>
          <div className="kpi-label">Ativos</div>
          <div className="kpi-value" style={{ color: 'var(--success)' }}>{data.ativos}</div>
          <div className="kpi-sub">{((data.ativos / data.total_funcionarios) * 100).toFixed(1)}% do quadro</div>
        </div>
        <div className="kpi-card">
          <div className="kpi-icon" style={{ background: 'var(--danger-muted)', color: 'var(--danger)' }}>✕</div>
          <div className="kpi-label">Desligados</div>
          <div className="kpi-value" style={{ color: 'var(--danger)' }}>{data.demitidos}</div>
          <div className="kpi-sub">{((data.demitidos / data.total_funcionarios) * 100).toFixed(1)}% turnover</div>
        </div>
        <div className="kpi-card">
          <div className="kpi-icon" style={{ background: 'var(--warning-muted)', color: 'var(--warning)' }}>📝</div>
          <div className="kpi-label">Ajustes Pendentes</div>
          <div className="kpi-value" style={{ color: 'var(--warning)' }}>{data.ajustes_pendentes}</div>
          <div className="kpi-sub">Aguardando aprovação</div>
        </div>
      </div>

      <div className="grid-2 mb-24">
        {/* Admissões por Ano */}
        <div className="card">
          <div className="card-header"><h3>Admissões por Ano</h3></div>
          <div className="card-body">
            <div className="chart-bars">
              {data.admissoes_por_ano.map(a => (
                <div key={a.ano} className="chart-bar-col">
                  <div style={{ fontSize: '10px', color: 'var(--text-secondary)', fontWeight: 700 }}>{a.total}</div>
                  <div className="chart-bar" style={{ height: `${(a.total / maxAdm) * 100}%` }}></div>
                  <div className="chart-bar-label">{a.ano}</div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Distribuição por Setor */}
        <div className="card">
          <div className="card-header"><h3>Distribuição por Setor</h3></div>
          <div className="card-body">
            <div className="dist-list">
              {data.por_setor.map(s => (
                <div key={s.setor} className="dist-item">
                  <div className="dist-label">{s.setor}</div>
                  <div className="dist-bar-track">
                    <div className="dist-bar-fill" style={{ width: `${(s.total / maxSetor) * 100}%` }}></div>
                  </div>
                  <div className="dist-value">{s.total}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div className="grid-2">
        {/* Empresas */}
        <div className="card">
          <div className="card-header"><h3>Empresas do Grupo</h3></div>
          <div className="card-body no-padding">
            <div className="table-wrapper">
              <table className="data-table">
                <thead><tr><th>Razão Social</th><th>CNPJ</th><th className="text-right">Funcionários</th></tr></thead>
                <tbody>
                  {data.empresas.map(e => (
                    <tr key={e.id}>
                      <td style={{ fontWeight: 600 }}>{e.razao_social}</td>
                      <td className="text-muted">{e.cnpj}</td>
                      <td className="text-right">{e.total_funcionarios}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Categorias */}
        <div className="card">
          <div className="card-header"><h3>Funcionários por Categoria</h3></div>
          <div className="card-body">
            <div className="dist-list">
              {data.por_categoria.map(c => (
                <div key={c.categoria} className="dist-item">
                  <div className="dist-label">{c.categoria}</div>
                  <div className="dist-bar-track">
                    <div className="dist-bar-fill" style={{ width: `${(c.total / data.total_funcionarios) * 100}%` }}></div>
                  </div>
                  <div className="dist-value">{c.total}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
