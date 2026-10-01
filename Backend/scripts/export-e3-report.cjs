// Exporta únicamente resultados de pruebas: excluye logs, tokens y mensajes de fallo.
const { readFileSync, writeFileSync, mkdirSync } = require('node:fs');
const { join, basename } = require('node:path');
const backend = join(__dirname, '..');
const input = JSON.parse(readFileSync(join(backend, '.test-postgres-runtime/e3-results.json'), 'utf8'));
const output = join(backend, 'reports');
mkdirSync(output, { recursive: true });
const files = {
  'must.e3-spec.ts': ['e3-must-summary.json', 'API y PostgreSQL reales; verificación externa de Firebase sustituida.'],
  'salud.e3-spec.ts': ['salud-summary.json', 'SELECT 1 con PostgreSQL real local; caso exitoso.'],
  'reserva-validacion.e3-spec.ts': ['validacion-400-summary.json', 'API y PostgreSQL reales sin mocks; 400 y ninguna reserva persistida.'],
  'menor-privilegio.e3-spec.ts': ['menor-privilegio-summary.json', 'Servicios, JWT y PostgreSQL reales sin mocks; Google externo no ejecutado.'],
};
const suites = [];
for (const result of input.testResults) {
  const name = basename(result.name);
  if (!files[name]) continue;
  const [filename, alcance] = files[name];
  const tests = result.assertionResults.map(test => ({ escenario: test.fullName, estado: test.status }));
  const report = { ejecutadoDesde: new Date(input.startTime).toISOString(), entorno: 'PostgreSQL local exclusivo E3',
    archivoPrueba: `Backend/test/e3/${name}`, alcance, total: tests.length,
    aprobadas: tests.filter(t => t.estado === 'passed').length,
    fallidas: tests.filter(t => t.estado === 'failed').length, pruebas: tests };
  writeFileSync(join(output, filename), JSON.stringify(report, null, 2) + '\n');
  suites.push({ reporte: `Backend/reports/${filename}`, total: report.total, aprobadas: report.aprobadas, fallidas: report.fallidas });
}
writeFileSync(join(output, 'e3-summary.json'), JSON.stringify({ ejecutadoDesde: new Date(input.startTime).toISOString(),
  exito: input.success, total: input.numTotalTests, aprobadas: input.numPassedTests, fallidas: input.numFailedTests,
  produccionVerificada: false, suites }, null, 2) + '\n');
console.log(`Reportes exportados: ${suites.length} suites, ${input.numPassedTests}/${input.numTotalTests} aprobadas.`);