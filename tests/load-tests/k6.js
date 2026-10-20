import http from "k6/http";
import { check, sleep } from 'k6';

export const options = {
    vus: 20,
    duration: '300s',
  };

export default function () {
    //const res = http.get('https://blog.sarwa.co/');
    const res = http.get('https://www.stage.sarwa.co/blog');
    check(res, { 'status was 200': (r) => r.status == 200 });
};
