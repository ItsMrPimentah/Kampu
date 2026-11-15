import 'reflect-metadata';
import assert from 'node:assert/strict';
import test from 'node:test';
import { METHOD_METADATA, PATH_METADATA } from '@nestjs/common/constants';
import { RequestMethod } from '@nestjs/common';
import SwaggerParser from '@apidevtools/swagger-parser';
import { HealthController } from '../src/health.controller';
import { AuthController } from '../src/modules/identity/auth.controller';
import { IdentityController } from '../src/modules/identity/identity.controller';
import { CommunityController } from '../src/modules/community/community.controller';
import { openApiDocument } from '../src/openapi';

test('OpenAPI is valid and covers every exposed controller operation', async () => {
  await SwaggerParser.validate(JSON.parse(JSON.stringify(openApiDocument)));
  const actual: string[] = [];
  for (const controller of [HealthController, AuthController, IdentityController, CommunityController]) {
    const prefix = Reflect.getMetadata(PATH_METADATA, controller) as string;
    for (const name of Object.getOwnPropertyNames(controller.prototype)) {
      const handler: unknown = Object.getOwnPropertyDescriptor(controller.prototype, name)?.value;
      if (typeof handler !== 'function') continue;
      const method = Reflect.getMetadata(METHOD_METADATA, handler) as RequestMethod | undefined;
      if (method === undefined) continue;
      const suffix = Reflect.getMetadata(PATH_METADATA, handler) as string;
      const path = `/${[prefix, suffix].filter(part => part && part !== '/').join('/')}`.replace(/:([^/]+)/g, '{$1}');
      actual.push(`${RequestMethod[method].toLowerCase()} ${path}`);
    }
  }
  const documented = Object.entries(openApiDocument.paths).flatMap(([path, item]) =>
    Object.keys(item).filter(key => ['get', 'post', 'patch', 'put', 'delete'].includes(key)).map(method => `${method} ${path}`),
  );
  assert.deepEqual(documented.sort(), actual.sort());
});

test('authentication and action parameters describe the actual HTTP contract', () => {
  const paths = openApiDocument.paths;
  assert.equal(paths['/auth/login'].post?.security, undefined);
  assert.deepEqual(paths['/community/teams'].get?.security, [{ bearerAuth: [] }]);
  assert.ok(paths['/auth/login'].post?.responses['201']);
  const action = paths['/community/challenges/{id}/{action}'].post?.parameters?.find(parameter => 'name' in parameter && parameter.name === 'action');
  assert.ok(action && 'schema' in action && action.schema && 'enum' in action.schema);
  assert.ok(action.schema.enum?.includes('field-approve'));
});
