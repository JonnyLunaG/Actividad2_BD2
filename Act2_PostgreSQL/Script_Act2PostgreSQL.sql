
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
SELECT definition
FROM pg_views
WHERE viewname = 'vista_profesores';

 -- punto 5.5
SELECT * FROM vista_profesores;

 -- punto 5.6
CREATE OR REPLACE VIEW vista_profesores AS
SELECT u.primernombre, u.segundonombre, u.apellido1, u.apellido2, p.tipoprofesor,c.salario, p.idnif
FROM usuarios u
INNER JOIN profesores p ON u.idusuario = p.usuarios_idusuario
INNER JOIN contratos c ON p.idnif= c.profesores_idNIF
WHERE salario > 2500000
ORDER BY apellido1;

 -- punto 5.7
 SELECT * FROM vista_profesores;


