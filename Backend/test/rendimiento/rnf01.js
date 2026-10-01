import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL =
    __ENV.BASE_URL || 'https://mesachapaca-api.onrender.com';

const RESTAURANTE_ID = __ENV.RESTAURANTE_ID || '24';
const FECHA = __ENV.FECHA || '2026-10-03';
const HORA = __ENV.HORA || '14:00';
const TOKEN = __ENV.TOKEN;
if (!TOKEN) throw new Error('Define TOKEN con una sesión de prueba válida.');

export const options = {
    vus: 1,
    iterations: 10,

    thresholds: {
        'http_req_duration{endpoint:restaurantes}': ['p(90)<3000'],
        'http_req_duration{endpoint:menus}': ['p(90)<3000'],
        'http_req_duration{endpoint:disponibilidad}': ['p(90)<3000'],
    },
};

const params = {
    headers: {
        Authorization: `Bearer ${TOKEN}`,
    },
};

export default function () {
    const restaurantes = http.get(
        `${BASE_URL}/api/v1/restaurante`,
        {
            ...params,
            tags: { endpoint: 'restaurantes' },
        }
    );

    console.log(
        `RESTAURANTES -> status=${restaurantes.status}`
    );

    check(restaurantes, {
        'restaurantes responde 200': (r) => r.status === 200,
    });

    sleep(1);

    const menus = http.get(
        `${BASE_URL}/api/v1/menu/restaurante/${RESTAURANTE_ID}`,
        {
            ...params,
            tags: { endpoint: 'menus' },
        }
    );

    console.log(
        `MENUS -> status=${menus.status}`
    );

    check(menus, {
        'menus responde 200': (r) => r.status === 200,
    });

    sleep(1);

    const disponibilidad = http.get(
        `${BASE_URL}/api/v1/reservas/disponibilidad` +
        `?idRestaurante=${RESTAURANTE_ID}` +
        `&fecha=${FECHA}` +
        `&hora=${HORA}` +
        `&numeroPersonas=1` +
        `&duracionMinutos=60`,
        {
            ...params,
            tags: { endpoint: 'disponibilidad' },
        }
    );

    console.log(
        `DISPONIBILIDAD -> status=${disponibilidad.status}`
    );

    check(disponibilidad, {
        'disponibilidad responde 200': (r) => r.status === 200,
    });

    sleep(1);
}