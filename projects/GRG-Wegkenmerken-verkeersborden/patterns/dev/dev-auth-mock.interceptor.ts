import { HttpEvent, HttpHandler, HttpInterceptor, HttpRequest, HttpResponse } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';
import { DEV_ACTIVE_PERSONA, DEV_AUTH_MOCK_ENABLED } from './dev-auth-mock.config';

@Injectable()
export class DevAuthMockInterceptor implements HttpInterceptor {
  intercept(req: HttpRequest<unknown>, next: HttpHandler): Observable<HttpEvent<unknown>> {
    if (!DEV_AUTH_MOCK_ENABLED) {
      return next.handle(req);
    }

    if (req.method === 'GET' && /\/api\/organizations\/[^/]+$/.test(req.url)) {
      console.log(`[DEV MOCK] Intercepted org request: ${req.url}`);
      console.log(`[DEV MOCK] Active persona: ${DEV_ACTIVE_PERSONA.label}`);
      return of(new HttpResponse({ status: 200, body: DEV_ACTIVE_PERSONA.organization }));
    }

    return next.handle(req);
  }
}
