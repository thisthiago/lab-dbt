import { useState, useEffect } from 'react';

export default function Dashboard({ system, onSelectSystem, onSelectEmployee, onLogout }) {
  const [employees, setEmployees] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (system) {
      setLoading(true);
      fetch(`http://localhost:8000/api/${system}/funcionarios`)
        .then(res => res.json())
        .then(data => {
          setEmployees(data);
          setLoading(false);
        });
    }
  }, [system]);

  if (!system) {
    return (
      <div className="container" style={{ textAlign: 'center', marginTop: '10vh' }}>
        <h1 style={{ marginBottom: '40px' }}>Selecione o Sistema</h1>
        <div className="grid grid-cols-2" style={{ maxWidth: '600px', margin: '0 auto' }}>
          <div className="glass glass-card" style={{ cursor: 'pointer' }} onClick={() => onSelectSystem('admin')}>
            <h3>Administração</h3>
            <p style={{ color: 'var(--text-secondary)', marginTop: '10px' }}>Funcionários e Estagiários</p>
          </div>
          <div className="glass glass-card" style={{ cursor: 'pointer' }} onClick={() => onSelectSystem('motoristas')}>
            <h3>Motoristas</h3>
            <p style={{ color: 'var(--text-secondary)', marginTop: '10px' }}>Logística e Transporte</p>
          </div>
        </div>
        <button className="btn" style={{ marginTop: '40px', background: 'transparent', border: '1px solid var(--surface-border)' }} onClick={onLogout}>
          Sair
        </button>
      </div>
    );
  }

  return (
    <div className="container">
      <div className="header">
        <div>
          <button className="btn" style={{ background: 'transparent', border: '1px solid var(--surface-border)', marginBottom: '10px', padding: '6px 12px' }} onClick={() => onSelectSystem(null)}>
            &larr; Voltar
          </button>
          <h1>Sistema de {system === 'admin' ? 'Administração' : 'Motoristas'}</h1>
        </div>
        <button className="btn" onClick={onLogout}>Sair</button>
      </div>

      <div className="glass glass-card">
        {loading ? <p>Carregando funcionários...</p> : (
          <div className="table-container">
            <table>
              <thead>
                <tr>
                  <th>Nome</th>
                  <th>CPF</th>
                  <th>Cargo</th>
                  <th>Categoria</th>
                  <th>Status</th>
                  <th>Ação</th>
                </tr>
              </thead>
              <tbody>
                {employees.map(emp => (
                  <tr key={emp.id}>
                    <td>{emp.nome}</td>
                    <td>{emp.cpf}</td>
                    <td>{emp.cargo}</td>
                    <td>{emp.categoria}</td>
                    <td>
                      <span className={`badge ${emp.status === 'Ativo' ? 'success' : 'danger'}`}>
                        {emp.status}
                      </span>
                    </td>
                    <td>
                      <button className="btn" style={{ padding: '6px 12px' }} onClick={() => onSelectEmployee(emp.id)}>
                        Ver Pontos
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
