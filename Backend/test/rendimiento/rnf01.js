import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL =
    __ENV.BASE_URL || 'https://mesachapaca-api.onrender.com';

const RESTAURANTE_ID = __ENV.RESTAURANTE_ID || '24';
const FECHA = __ENV.FECHA || '2026-10-03';
const HORA = __ENV.HORA || '14:00';
const TOKEN = __ENV.TOKEN || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjI5LCJjb3JyZW8iOiJhbGluYS52YWxjYXphci42MzgyN0BnbWFpbC5jb20iLCJwZXJtaXNvcyI6WyJtZW51X2Rhc2hib2FyZCIsIm1lbnVfcmVzZW5hcyIsIm1lbnVfc29wb3J0ZSIsIm1lbnVfcGVyZmlsX3Jlc3RhdXJhbnRlIiwibWVudV9tZXNhcyIsIm1lbnVfbWVudXMiLCJtZW51X3Jlc2VydmFzIl0sInN2IjowLCJzZXNzaW9uU3RhcnRlZEF0IjoxNzkwODc0OTc5LCJpYXQiOjE3OTA4NzQ5NzksImV4cCI6MTc5MDg3ODU3OSwiYXVkIjoibWVzYS1jaGFwYWNhLWFwcCIsImlzcyI6Im1lc2EtY2hhcGFjYSJ9.LDmN1Ib2s3VNNo2lNnLHFqJJrBZZkCVGkqPudOHd-vY';

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