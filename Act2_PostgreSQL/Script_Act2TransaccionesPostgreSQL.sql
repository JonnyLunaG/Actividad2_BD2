
--Punto 5.9.2
CREATE TABLE deudores (
cc INT PRIMARY KEY NOT NULL,
clave VARCHAR (15) NOT NULL,
nombre VARCHAR (30) NOT NULL,
apellido VARCHAR (30) NOT NULL,
email VARCHAR (50) NOT NULL
);

--Punto 5.9.3
CREATE TABLE creditos(
id SERIAL PRIMARY KEY NOT NULL,
fecha DATE NOT NULL,
valor FLOAT NOT NULL,
cuotas INT NOT NULL,
interes_mes FLOAT NOT NULL,
estado VARCHAR (20) NOT NULL DEFAULT 'Activo',
deudor_id INT NOT NULL,
CONSTRAINT chk_interesmes
CHECK (interes_mes>=0 AND interes_mes<=1),
FOREIGN KEY (deudor_id) REFERENCES deudores (cc)
ON DELETE CASCADE ON UPDATE CASCADE
);

--Punto 5.9.4
CREATE TABLE pagos(
id SERIAL PRIMARY KEY NOT NULL,
fecha DATE NOT NULL,
valor FLOAT NOT NULL ,
credito_id INT NOT NULL,
CONSTRAINT chk_valor_positivo CHECK(valor>0),
FOREIGN KEY (credito_id) REFERENCES creditos (id)
ON DELETE CASCADE ON UPDATE CASCADE
);

-- Agregar la restricción CHECK a la columna fecha
ALTER TABLE pagos
ADD CONSTRAINT fecha_check CHECK (fecha <= current_date);

--Punto 5.9.5
INSERT INTO deudores
VALUES(123, 'Abc', 'Fulanito', 'Detal', 'fulanito1@gmail.com'),
(456, 'B15', 'Mengano', 'Guerrero', 'mengano@hotmail.com'),
(789, 'w86', 'Prencejo', 'Tapias', 'prencejo@yahoo.com'),
(951, 'y84', 'Riquilda', 'López', 'riquilda@gmail.com');

--Punto 5.9.6
SELECT * FROM deudores;

--Punto 5.9.7
INSERT INTO creditos (fecha, valor, cuotas, interes_mes, deudor_id) 
VALUES(CURRENT_DATE-INTERVAL '1 year',100000,5,0.4,'123'),
(CURRENT_DATE-INTERVAL '1 year',200000,10,0.2,'456'),
(CURRENT_DATE-INTERVAL '1 year',300000,12,0.2,'789'),
(CURRENT_DATE-INTERVAL '1 year',700000,6,0.2,'951');

--Punto 5.9.8
SELECT * FROM creditos;

--Punto 5.9.9
CREATE OR REPLACE PROCEDURE InsertarPago
(pago_id INTEGER,
pago_fecha DATE,
pago_valor FLOAT,
credito_id INTEGER)
LANGUAGE plpgsql
AS $$

BEGIN
	    INSERT INTO pagos (id, fecha, valor, credito_id)
    	VALUES (pago_id, pago_fecha, pago_valor, credito_id);

    IF FOUND THEN
		RAISE NOTICE 'El pago con Id % 
		del credito con Id %
		ha sistematizado Exitosamente! ',pago_id, credito_id ;
	ELSE 
		RAISE NOTICE 'Error al intentar hacer el pago' ;
	END IF;
END;
$$;

--Punto 5.9.9.1
SELECT fecha FROM creditos WHERE id = 1;
CALL InsertarPago(1, '2022-07-15', 28000, 1);

--Punto 5.9.9.2
CALL InsertarPago(2, '2023-21-06', 28000, 1);

--Punto 5.9.9.3
CALL InsertarPago(3, '2022-08-15', 28000, 1);

--Punto 5.9.9.4
CALL InsertarPago(4, '2022-08-15', 28000, 1);

--Punto 5.9.9.5
CALL InsertarPago(5, '2022-08-15', -28000, 1);

DROP PROCEDURE IF EXISTS EstadoCredito;

--Punto 5.9.10
CREATE OR REPLACE PROCEDURE EstadoCredito(IN c_credito_id INTEGER) 
LANGUAGE plpgsql
AS $$
DECLARE
	valor_credito FLOAT;
    tasa_interes FLOAT;
    valor_deuda FLOAT;
    valor_saldo FLOAT;
    valor_pagado FLOAT;
    estado_actual VARCHAR(20);
    estado_final VARCHAR(20);
BEGIN 
    -- Obtenemos el valor del crédito y la tasa de interés
    SELECT valor, interes_mes, estado INTO valor_credito, tasa_interes, estado_actual
    FROM creditos
    WHERE id = c_credito_id;
    
    -- Calculamos el valor de la deuda
    valor_deuda := valor_credito *(1+ tasa_interes);
    
    -- Calculamos el valor total pagado
    SELECT SUM(valor) INTO valor_pagado
    FROM pagos
    WHERE pagos.credito_id = c_credito_id;
    
    -- calculamos el saldo
    valor_saldo = valor_deuda - valor_pagado;
    -- Determinar el estado del crédito
    IF valor_pagado >= valor_deuda THEN
        estado_final := 'Finalizado';
    ELSE
        estado_final := estado_actual;
    END IF;
    
    -- Actualizar el estado del crédito en la tabla Creditos
    UPDATE creditos
    SET estado = estado_final
    WHERE id = c_credito_id;    
    -- enviamos un mensaje con el estado final del credito
    RAISE NOTICE 'El estado actual del crédito con Id % es %', c_credito_id, estado_final;
END; 
$$;

CALL EstadoCredito(1);

CALL InsertarPago(2, '2022-08-15', 28000, 1);

CALL InsertarPago(5, '2022-08-15', 28000, 1);

CALL EstadoCredito(1);

--Punto 5.9.11
SELECT * FROM creditos 
WHERE id=1;

--Punto 5.9.12
SELECT * FROM pagos
WHERE credito_id= 1;

--Punto 5.9.13
SELECT SUM(valor) AS "TOTAL PAGOS" 
FROM pagos
WHERE credito_id = 1
GROUP BY credito_id;

--Punto 5.9.15
DELETE FROM pagos WHERE credito_id=1;

--Punto 5.9.16
SELECT * FROM pagos
WHERE credito_id= 1;

DROP PROCEDURE insertar_pagos;
--Punto 5.9.17
CREATE OR REPLACE PROCEDURE insertar_pagos(
    p_pago_id INTEGER,
    p_fecha DATE,
    p_valor FLOAT,
    p_credito_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE 
	v_error_message TEXT;
BEGIN
	--se inicia la transacción
    BEGIN
		-- Validar que el valor del pago sea positivo
		IF p_valor <= 0 THEN
			RAISE EXCEPTION 'El valor del pago debe ser mayor que cero.';
		END IF;

		-- Validar que la fecha de pago no sea mayor que la fecha actual
		IF p_fecha > CURRENT_DATE THEN
			RAISE EXCEPTION 'La fecha de pago no puede ser mayor que la fecha actual.';
		END IF;

    	BEGIN
		
			INSERT INTO pagos (id, fecha, valor, credito_id)
			VALUES (p_pago_id, p_fecha, p_valor, p_credito_id);
			EXCEPTION
				WHEN OTHERS THEN
					GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
					RAISE NOTICE 'Error al insertar el pago: %', v_error_message;
					RETURN;
    		END;
			COMMIT;
	END;
	   
    RAISE NOTICE 'El pago con ID % ha sido insertado exitosamente.', p_pago_id;
END;
$$ ;

SELECT fecha FROM creditos WHERE id = 1;

--Punto 5.9.18.1
CALL Insertar_Pagos(1, '2022-07-15', 28000, 1);

--Punto 5.9.18.2
CALL Insertar_Pagos(2, '2023-07-23', 28000, 1);

--Punto 5.9.18.3
CALL Insertar_Pagos(3, '2022-08-15', 28000, 1);

--Punto 5.9.18.4
CALL Insertar_Pagos(4, '2022-08-15', 28000, 1);

--Punto 5.9.18.5
CALL Insertar_Pagos(5, '2022-08-15', -28000, 1);

--Punto 5.9.19
CALL EstadoCredito(1);

CALL Insertar_Pagos(2, '2022-07-23', 28000, 1);

CALL Insertar_Pagos(5, '2022-08-15', 28000, 1);

CALL EstadoCredito(1);

--Punto 5.9.20
SELECT * FROM creditos WHERE id= 1;

--Punto 5.9.21
SELECT * FROM pagos
WHERE credito_id = 1;
--Punto 5.9.22
SELECT SUM(valor) AS "TOTAL PAGOS"
FROM pagos
WHERE credito_id = 1
GROUP BY credito_id;

--Punto 5.9.23
ROLLBACK;

--Punto 5.9.24
SELECT * FROM pagos
WHERE credito_id= 1;

--Punto 5.9.25
SELECT SUM(valor) AS "TOTAL PAGOS"
FROM pagos
WHERE credito_id = 1
GROUP BY credito_id;

SELECT * FROM deudores;

SELECT * FROM creditos;

--Punto 5.10.1
SELECT d.nombre, (
    SELECT COUNT(*)
    FROM creditos c
    WHERE c.deudor_id = d.cc
        AND c.estado = 'Activo'
) AS total_creditos_activos
FROM deudores d;

--Punto 5.10.2
SELECT d.nombre, c.valor_credito
FROM deudores d, (
    SELECT deudor_id, sum(valor) AS valor_credito
    FROM creditos
    GROUP BY deudor_id) c
WHERE d.cc = c.deudor_id;

--Punto 5.10.3
SELECT d.nombre
FROM deudores d
WHERE d.cc IN (
    SELECT c.deudor_id
    FROM creditos c
    WHERE c.estado = 'Activo');

--Punto 5.10.4
SELECT d.nombre, COUNT(c.id) AS total_creditos_activos
FROM deudores d
JOIN creditos c ON d.cc = c.deudor_id
WHERE c.estado = 'Activo'
GROUP BY d.cc
HAVING COUNT(c.id) > (
    SELECT AVG(total_creditos)
    FROM (
        SELECT COUNT(id) AS total_creditos
        FROM creditos
        WHERE estado = 'Activo'
        GROUP BY deudor_id
    ) AS subconsulta);

--Punto 5.10.5
ALTER TABLE deudores
ADD CONSTRAINT chk_cc
CHECK (cc > 0);

INSERT INTO deudores (cc, clave, nombre, apellido, email)
VALUES(-654, 'Abc', 'Jonny', 'Luna', 'jonnylunag@gmail.com')

--Punto 5.10.6
SELECT d.nombre, c.fecha, c.valor
FROM deudores d
INNER JOIN creditos c ON d.cc = c.deudor_id;

--Punto 5.10.7
SELECT d.cc, d.nombre, d.apellido
FROM deudores d
FULL JOIN creditos  ON d.cc = creditos.deudor_id;

--Punto 5.10.8
SELECT d.nombre, d.apellido, c.cuotas, c.valor
FROM deudores d
LEFT OUTER JOIN creditos c ON d.cc = c.deudor_id;

--Punto 5.10.9
SELECT d.nombre, c.cuotas, c.valor, c.interes_mes
FROM deudores d
LEFT JOIN creditos c ON d.cc = c.deudor_id;

--Punto 5.10.10
SELECT c.id, c.valor, p.fecha, p.valor
FROM creditos c
RIGHT JOIN pagos p ON c.id = p.credito_id;

--Punto 5.10.11
SELECT id FROM creditos
UNION 
SELECT credito_id FROM pagos;

--Punto 5.10.12
SELECT cc
FROM deudores
INTERSECT
SELECT deudor_id
FROM creditos;

SELECT d.cc, d.nombre
FROM deudores d
INNER JOIN creditos c ON d.cc = c.deudor_id
WHERE d.cc IN (SELECT deudor_id FROM creditos);

--Punto 5.10.13
CREATE VIEW VistaDeudoresCreditos AS
SELECT d.nombre, c.fecha, c.valor
FROM deudores d
INNER JOIN creditos c ON d.cc = c.deudor_id;

SELECT * FROM VistaDeudoresCreditos;

--Punto 5.10.14
SELECT nombre, valor
FROM VistaDeudoresCreditos
WHERE valor > 100000;

--Punto 5.10.15
CREATE OR REPLACE VIEW VistaDeudoresCreditos AS
SELECT d.nombre, c.fecha, c.valor, c.cuotas
FROM deudores d
INNER JOIN creditos c ON d.cc = c.deudor_id
WHERE c.estado = 'Activo';

--Punto 5.10.16
SELECT * FROM VistaDeudoresCreditos;

--Punto 5.10.17
SELECT viewname AS table_name
FROM pg_views
WHERE schemaname = 'public';

--Punto 5.10.18
DROP VIEW VistaDeudoresCreditos;

--Punto 5.10.19
START TRANSACTION;
--Insertar ocho nuevos registros de pago en la tabla "Pagos" al credito con id = 2
INSERT INTO pagos (id,fecha, valor, credito_id)
VALUES (6,'2022-07-15',24000, 2);

--Actualizamos la tabla creditos
UPDATE creditos
SET valor = valor-20000
WHERE id = 2;

COMMIT;

--Punto 5.10.20
CREATE OR REPLACE PROCEDURE insertar_pagos2(
    p_pago_id INTEGER,
    p_fecha DATE,
    p_valor FLOAT,
    p_credito_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE 
	v_error_message TEXT;
BEGIN
	--se inicia la transacción
    BEGIN
		-- Validar que el valor del pago sea positivo
		IF p_valor <= 0 THEN
			RAISE EXCEPTION 'El valor del pago debe ser mayor que cero.';
		END IF;

		-- Validar que la fecha de pago no sea mayor que la fecha actual
		IF p_fecha > CURRENT_DATE THEN
			RAISE EXCEPTION 'La fecha de pago no puede ser mayor que la fecha actual.';
		END IF;

    	BEGIN
		
			INSERT INTO pagos (id, fecha, valor, credito_id)
			VALUES (p_pago_id, p_fecha, p_valor, p_credito_id);
			EXCEPTION
				WHEN OTHERS THEN
					GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
					RAISE NOTICE 'Error al insertar el pago: %', v_error_message;
					RETURN;
    		END;
			COMMIT;
	END;
	   
    RAISE NOTICE 'El pago con ID % ha sido insertado exitosamente.', p_pago_id;
END;
$$ ;

CALL insertar_pagos2(7,'2022-08-04',-28000,2);

CALL insertar_pagos2(8,'2025-08-04',28000,2);

CALL insertar_pagos2(7,'2022-08-04',24000,2);

/*****/


SELECT cc
FROM deudores
INTERSECT
SELECT deudor_id
FROM creditos;




/******/

/*****/

SELECT * FROM creditos;
SELECT * FROM pagos;
SELECT * FROM deudores;

DELETE FROM pagos WHERE credito_id=2;
SELECT valor, interes_mes, estado
FROM creditos
WHERE id = 1;


/*******/


