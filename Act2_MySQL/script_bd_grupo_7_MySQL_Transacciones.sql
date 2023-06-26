
-- punto 5.2
SELECT u.primernombre, u.segundonombre, u.apellido1, u.apellido2, p.tipoprofesor, c.salario
FROM usuarios u
INNER JOIN profesores p ON u.idusuario = p.usuarios_idusuario
INNER JOIN contratos c ON p.idnif= c.profesores_idNIF;

-- punto 5.3
CREATE VIEW vista_profesores AS
SELECT u.primernombre, u.segundonombre, u.apellido1, u.apellido2, p.tipoprofesor, c.salario
FROM usuarios u
INNER JOIN profesores p ON u.idusuario = p.usuarios_idusuario
INNER JOIN contratos c ON p.idnif= c.profesores_idNIF;

-- punto 5.4
SHOW CREATE VIEW vista_profesores;

-- punto 5.5
SELECT * FROM vista_profesores;

-- punto 5.6
ALTER VIEW vista_profesores AS
SELECT p. idnif, u.apellido1, u.apellido2, u.primernombre, u.segundonombre, p.tipoprofesor, c.salario
FROM usuarios u
INNER JOIN profesores p ON u.idusuario = p.usuarios_idusuario
INNER JOIN contratos c ON p.idnif= c.profesores_idNIF
WHERE salario > 2500000
ORDER BY apellido1;   

-- punto 5.7
SELECT * FROM vista_profesores;