import { useState, useEffect } from 'react';
import { api } from '../api';
import DashboardPage from './DashboardPage';
import FuncionariosPage from './FuncionariosPage';
import FuncionarioDetail from './FuncionarioDetail';
import AjustesPage from './AjustesPage';
import FeriasPage from './FeriasPage';

const NAV_ITEMS = [
  { key: 'dashboard', label: 'Painel Geral', icon: '📊' },
  { key: 'funcionarios', label: 'Funcionários', icon: '👥' },
  { key: 'ajustes', label: 'Ajustes de Ponto', icon: '📝' },
  { key: 'ferias', label: 'Férias', icon: '🏖️' },
];

export default function AppShell({ system, onChangeSystem, onLogout }) {
  const [page, setPage] = useState('dashboard');
  const [selectedEmployee, setSelectedEmployee] = useState(null);
  const [dashData, setDashData] = useState(null);

  useEffect(() => {
    api.dashboard(system).then(setDashData).catch(console.error);
  }, [system]);

  const systemLabel = system === 'admin' ? 'Administração' : 'Motoristas';

  const navigate = (key) => {
    setPage(key);
    setSelectedEmployee(null);
  };

  const openEmployee = (id) => {
    setSelectedEmployee(id);
    setPage('employee-detail');
  };

  const breadcrumb = () => {
    if (page === 'employee-detail') return ['Funcionários', 'Detalhes'];
    const item = NAV_ITEMS.find(n => n.key === page);
    return [item?.label || page];
  };

  const renderPage = () => {
    if (page === 'employee-detail' && selectedEmployee) {
      return <FuncionarioDetail system={system} id={selectedEmployee} onBack={() => navigate('funcionarios')} />;
    }
    switch (page) {
      case 'dashboard': return <DashboardPage data={dashData} />;
      case 'funcionarios': return <FuncionariosPage system={system} onSelect={openEmployee} />;
      case 'ajustes': return <AjustesPage system={system} onSelectEmployee={openEmployee} />;
      case 'ferias': return <FeriasPage system={system} onSelectEmployee={openEmployee} />;
      default: return <DashboardPage data={dashData} />;
    }
  };

  return (
    <div className="app-layout">
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="sidebar-brand">
          <div className="sidebar-brand-icon">⏱</div>
          <div>
            <h2>Ponto RH</h2>
            <small>{systemLabel}</small>
          </div>
        </div>

        <div className="sidebar-section">
          <div className="sidebar-section-title">Menu Principal</div>
        </div>
        <nav className="sidebar-nav">
          {NAV_ITEMS.map(item => (
            <button
              key={item.key}
              className={`sidebar-link ${page === item.key ? 'active' : ''}`}
              onClick={() => navigate(item.key)}
            >
              <span className="icon">{item.icon}</span>
              {item.label}
              {item.key === 'ajustes' && dashData?.ajustes_pendentes > 0 && (
                <span className="link-badge">{dashData.ajustes_pendentes}</span>
              )}
            </button>
          ))}
        </nav>

        <div className="sidebar-footer">
          <button className="btn btn-secondary btn-sm btn-block" onClick={onChangeSystem} style={{ marginBottom: '8px' }}>
            🔄 Trocar Sistema
          </button>
          <div className="sidebar-user">
            <div className="sidebar-avatar">RH</div>
            <div className="sidebar-user-info">
              <div className="name">Analista RH</div>
              <div className="role">{systemLabel}</div>
            </div>
            <button className="btn btn-ghost btn-sm" onClick={onLogout} title="Sair">⏻</button>
          </div>
        </div>
      </aside>

      {/* Main */}
      <main className="main-content">
        <div className="topbar">
          <div className="topbar-breadcrumb">
            <span>{systemLabel}</span>
            {breadcrumb().map((b, i) => (
              <span key={i}><span className="sep">›</span> <span className={i === breadcrumb().length - 1 ? 'current' : ''}>{b}</span></span>
            ))}
          </div>
        </div>
        <div className="page-content">
          {renderPage()}
        </div>
      </main>
    </div>
  );
}
