import { useState } from 'react';
import Login from './pages/Login';
import SystemSelector from './pages/SystemSelector';
import AppShell from './pages/AppShell';

export default function App() {
  const [token, setToken] = useState(localStorage.getItem('token'));
  const [system, setSystem] = useState(null);

  const handleLogin = (t) => {
    setToken(t);
    localStorage.setItem('token', t);
  };

  const handleLogout = () => {
    setToken(null);
    setSystem(null);
    localStorage.removeItem('token');
  };

  if (!token) return <Login onLogin={handleLogin} />;
  if (!system) return <SystemSelector onSelect={setSystem} onLogout={handleLogout} />;

  return <AppShell system={system} onChangeSystem={() => setSystem(null)} onLogout={handleLogout} />;
}
