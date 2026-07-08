import { useState, useEffect, useCallback } from 'react';
import { api } from '../api';

export default function FuncionariosPage({ system, onSelect }) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [categoriaFilter, setCategoriaFilter] = useState('');
  const [searchTimeout, setSearchTimeout] = useState(null);

  const load = useCallback(async (p, s, st, cat) => {
    setLoading(true);
    try {
      const result = await api.funcionarios(system, { page: p, per_page: 20, search: s || undefined, status: st || undefined, categoria: cat || undefined });
      setData(result);
    } catch (e) { console.error(e); }
    setLoading(false);
  }, [system]);

  useEffect(() => { load(page, search, statusFilter, categoriaFilter); }, [page, statusFilter, categoriaFilter, load]);

  const handleSearch = (v) => {
    setSearch(v);
    if (searchTimeout) clearTimeout(searchTimeout);
    setSearchTimeout(setTimeout(() => { setPage(1); load(1, v, statusFilter, categoriaFilter); }, 400));
  };

  const formatCPF = (cpf) => cpf;
  const formatCurrency = (v) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(v);

  return (
    <>
      <div className="page-header">
        <h1>Funcionários</h1>
        <p>Consulte os colaboradores cadastrados no sistema</p>
      </div>

      <div className="card">
        {/* Toolbar */}
        <div className="toolbar">
          <div className="search-input-wrapper">
            <span className="search-icon">🔍</span>
            <input className="search-input" placeholder="Buscar por nome ou CPF..." value={search} onChange={e => handleSearch(e.target.value)} />
          </div>
          <select className="filter-select" value={statusFilter} onChange={e => { setStatusFilter(e.target.value); setPage(1); }}>
            <option value="">Todos Status</option>
            <option value="Ativo">Ativo</option>
            <option value="Demitido">Demitido</option>
          </select>
          <select className="filter-select" value={categoriaFilter} onChange={e => { setCategoriaFilter(e.target.value); setPage(1); }}>
            <option value="">Todas Categorias</option>
            <option value="Mensalista">Mensalista</option>
            <option value="Horista">Horista</option>
            <option value="Estagiário">Estagiário</option>
          </select>
        </div>

        {/* Table */}
        {loading ? (
          <div className="loading-wrapper"><div className="spinner"></div> Carregando...</div>
        ) : (
          <>
            <div className="table-wrapper">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Nome</th>
                    <th>CPF</th>
                    <th>Cargo</th>
                    <th>Setor</th>
                    <th>Categoria</th>
                    <th>Salário</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {data?.items?.map(emp => (
                    <tr key={emp.id} className="clickable" onClick={() => onSelect(emp.id)}>
                      <td style={{ fontWeight: 600 }}>{emp.nome}</td>
                      <td className="text-muted">{formatCPF(emp.cpf)}</td>
                      <td>{emp.cargo}</td>
                      <td>{emp.setor}</td>
                      <td><span className="badge badge-accent">{emp.categoria}</span></td>
                      <td>{formatCurrency(emp.salario)}</td>
                      <td>
                        <span className={`badge ${emp.status === 'Ativo' ? 'badge-success' : 'badge-danger'}`}>
                          {emp.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                  {data?.items?.length === 0 && (
                    <tr><td colSpan="7" className="empty-state">Nenhum funcionário encontrado</td></tr>
                  )}
                </tbody>
              </table>
            </div>

            {/* Pagination */}
            {data && data.pages > 1 && (
              <div className="pagination">
                <div className="pagination-info">
                  Mostrando <strong>{(data.page - 1) * data.per_page + 1}</strong> – <strong>{Math.min(data.page * data.per_page, data.total)}</strong> de <strong>{data.total}</strong>
                </div>
                <div className="pagination-buttons">
                  <button className="pagination-btn" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>Anterior</button>
                  {Array.from({ length: Math.min(data.pages, 7) }, (_, i) => {
                    let p;
                    if (data.pages <= 7) { p = i + 1; }
                    else if (page <= 4) { p = i + 1; }
                    else if (page >= data.pages - 3) { p = data.pages - 6 + i; }
                    else { p = page - 3 + i; }
                    return (
                      <button key={p} className={`pagination-btn ${p === page ? 'active' : ''}`} onClick={() => setPage(p)}>{p}</button>
                    );
                  })}
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
