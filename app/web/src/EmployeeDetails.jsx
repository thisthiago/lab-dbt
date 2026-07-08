import { useState, useEffect } from 'react';

export default function EmployeeDetails({ system, employeeId, onBack }) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`http://localhost:8000/api/${system}/funcionarios/${employeeId}`)
      .then(res => res.json())
      .then(d => {
        setData(d);
        setLoading(false);
      });
  }, [system, employeeId]);

  if (loading) {
    return <div className="container" style={{ textAlign: 'center', marginTop: '10vh' }}>Carregando dados...</div>;
  }

  const emp = data.funcionario;

  return (
    <div className="container">
      <div className="header">
        <div>
          <button className="btn" style={{ background: 'transparent', border: '1px solid var(--surface-border)', marginBottom: '10px', padding: '6px 12px' }} onClick={onBack}>
            &larr; Voltar
          </button>
          <h1>Perfil do Funcionário</h1>
        </div>
      </div>

      <div className="grid grid-cols-3" style={{ gap: '30px' }}>
        <div style={{ gridColumn: 'span 1' }}>
          <div className="glass glass-card" style={{ position: 'sticky', top: '20px' }}>
            <h2 style={{ marginBottom: '20px' }}>{emp.nome}</h2>
            <div style={{ marginBottom: '10px' }}>
              <strong style={{ color: 'var(--text-secondary)' }}>Status:</strong> 
              <span className={`badge ${emp.status === 'Ativo' ? 'success' : 'danger'}`} style={{ marginLeft: '10px' }}>{emp.status}</span>
            </div>
            <p style={{ marginBottom: '10px' }}><strong style={{ color: 'var(--text-secondary)' }}>Cargo:</strong> {emp.cargo}</p>
            <p style={{ marginBottom: '10px' }}><strong style={{ color: 'var(--text-secondary)' }}>Categoria:</strong> {emp.categoria}</p>
            <p style={{ marginBottom: '10px' }}><strong style={{ color: 'var(--text-secondary)' }}>Admissão:</strong> {new Date(emp.data_admissao).toLocaleDateString()}</p>
          </div>
        </div>

        <div style={{ gridColumn: 'span 2', display: 'flex', flexDirection: 'column', gap: '30px' }}>
          <div className="glass glass-card">
            <h3 style={{ marginBottom: '20px' }}>Últimos Apontamentos</h3>
            <div className="table-container" style={{ maxHeight: '300px', overflowY: 'auto' }}>
              <table>
                <thead>
                  <tr>
                    <th>Data e Hora</th>
                    <th>Tipo</th>
                  </tr>
                </thead>
                <tbody>
                  {data.apontamentos.map(apt => (
                    <tr key={apt.id}>
                      <td>{new Date(apt.data_hora).toLocaleString()}</td>
                      <td>
                        <span className={`badge ${apt.tipo === 'Entrada' ? 'primary' : 'danger'}`}>
                          {apt.tipo}
                        </span>
                      </td>
                    </tr>
                  ))}
                  {data.apontamentos.length === 0 && (
                    <tr><td colSpan="2" style={{ textAlign: 'center' }}>Nenhum apontamento recente</td></tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>

          <div className="glass glass-card">
            <h3 style={{ marginBottom: '20px' }}>Solicitações de Ajuste Recentes</h3>
            <div className="table-container">
              <table>
                <thead>
                  <tr>
                    <th>Data Solicitação</th>
                    <th>Motivo</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {data.ajustes.map(aj => (
                    <tr key={aj.id}>
                      <td>{new Date(aj.data_solicitacao).toLocaleDateString()}</td>
                      <td>{aj.motivo}</td>
                      <td>
                        <span className={`badge ${aj.status === 'Aprovado' ? 'success' : aj.status === 'Pendente' ? 'primary' : 'danger'}`}>
                          {aj.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                  {data.ajustes.length === 0 && (
                    <tr><td colSpan="3" style={{ textAlign: 'center' }}>Nenhuma solicitação</td></tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
