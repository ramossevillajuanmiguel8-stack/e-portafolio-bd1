-- =====================================================================
-- Consultas sobre el esquema HR (Oracle / SQL Developer)
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Traer todos los empleados que hayan tenido más de 2 cargos sin
--    contar el cargo actual. Mostrar el nombre del empleado y la
--    cantidad de cargos que ha tenido.
--    (job_history solo guarda cargos anteriores, el actual está en employees)
-- ---------------------------------------------------------------------
SELECT e.first_name || ' ' || e.last_name AS nombre,
       COUNT(*)                           AS cargos_anteriores
FROM hr.employees e
JOIN hr.job_history jh
    ON jh.employee_id = e.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name
HAVING COUNT(*) > 2;


-- ---------------------------------------------------------------------
-- 2. Buscar empleados que pertenezcan a UK pero que en el nombre, en la
--    tercera posición, tengan una letra "a" minúscula. Mostrar el nombre
--    y el apellido del empleado.
-- ---------------------------------------------------------------------
SELECT e.first_name AS nombre,
       e.last_name  AS apellido
FROM hr.employees e
JOIN hr.departments d ON d.department_id = e.department_id
JOIN hr.locations   l ON l.location_id   = d.location_id
WHERE l.country_id = 'UK'
  AND SUBSTR(e.first_name, 3, 1) = 'a';   -- equivalente: e.first_name LIKE '__a%'


-- ---------------------------------------------------------------------
-- 3. Traer todos los empleados cuya comisión sea diferente a NULL.
-- ---------------------------------------------------------------------
SELECT e.employee_id,
       e.first_name,
       e.last_name,
       e.commission_pct
FROM hr.employees e
WHERE e.commission_pct IS NOT NULL;


-- ---------------------------------------------------------------------
-- 4. Buscar la suma de todos los salarios, el salario máximo, el mínimo
--    y la desviación estándar de todos los empleados.
-- ---------------------------------------------------------------------
SELECT SUM(salary)              AS suma_salarios,
       MAX(salary)              AS salario_maximo,
       MIN(salary)              AS salario_minimo,
       ROUND(STDDEV(salary), 2) AS desviacion_estandar
FROM hr.employees;


-- ---------------------------------------------------------------------
-- 5. Clasificar el salario con un mensaje:
--    - menor a 1.000 dólares     -> 'pobrecito'
--    - menor a 3.000 dólares     -> 'sigue intentando'
--    - mayor a 5.000 dólares     -> 'ya esta'
--    - mayor a 10.000 dólares    -> 'buenos dias ingeniero'
--    - cualquier otro caso       -> 'otros'
--    (los "mayor a" van primero, del más alto al más bajo, para que
--     10.000+ no caiga en 'ya esta')
-- ---------------------------------------------------------------------
SELECT e.first_name,
       e.salary,
       CASE
           WHEN e.salary > 10000 THEN 'buenos dias ingeniero'
           WHEN e.salary > 5000  THEN 'ya esta'
           WHEN e.salary < 1000  THEN 'pobrecito'
           WHEN e.salary < 3000  THEN 'sigue intentando'
           ELSE 'otros'
       END AS mensaje
FROM hr.employees e;


-- ---------------------------------------------------------------------
-- 6. Mostrar todos los empleados cuyo salario sea mayor al promedio
--    de su departamento.
-- ---------------------------------------------------------------------
SELECT e.first_name,
       e.last_name,
       e.salary,
       e.department_id,
       ROUND(p.promedio_depto, 2) AS promedio_depto
FROM hr.employees e
JOIN (
    SELECT department_id,
           AVG(salary) AS promedio_depto
    FROM hr.employees
    GROUP BY department_id
) p
    ON p.department_id = e.department_id
WHERE e.salary > p.promedio_depto;


-- ---------------------------------------------------------------------
-- 7. Una empresa desea identificar empleados que cumplan todas las
--    condiciones:
--    1- su salario es superior al promedio de su departamento
--    2- fueron contratados después del empleado más antiguo del departamento
--    3- no tienen subordinados directos
--    4- su salario es inferior al salario máximo de su departamento
-- ---------------------------------------------------------------------
SELECT e.employee_id,
       e.first_name,
       e.last_name,
       e.salary,
       e.department_id
FROM hr.employees e
JOIN (
    SELECT department_id,
           AVG(salary)    AS promedio,
           MAX(salary)    AS salario_max,
           MIN(hire_date) AS fecha_del_empleado_mas_antiguo
    FROM hr.employees
    WHERE department_id IS NOT NULL
    GROUP BY department_id
) d_stats
    ON e.department_id = d_stats.department_id
LEFT JOIN hr.employees subordinado
    ON e.employee_id = subordinado.manager_id
WHERE subordinado.employee_id IS NULL                      -- 3: sin subordinados
  AND e.salary    > d_stats.promedio                       -- 1
  AND e.salary    < d_stats.salario_max                    -- 4
  AND e.hire_date > d_stats.fecha_del_empleado_mas_antiguo; -- 2
