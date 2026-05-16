# Referência de padrões de testes

Referência rápida para padrões comuns de testes na stack. Use junto com a skill `test-driven-development`.

## Índice

- [Estrutura do teste (Arrange-Act-Assert)](#estrutura-do-teste-arrange-act-assert)
- [Convenções de nomenclatura](#convenções-de-nomenclatura)
- [Asserções comuns](#asserções-comuns)
- [Padrões de mock](#padrões-de-mock)
- [Testes React/componentes](#testes-reactcomponentes)
- [Testes de API / integração](#testes-de-api--integração)
- [Testes E2E (Playwright)](#testes-e2e-playwright)
- [Antipadrões de teste](#antipadrões-de-teste)

## Estrutura do teste (Arrange-Act-Assert)

```typescript
it('describes expected behavior', () => {
  // Arrange: dados e pré-condições
  const input = { title: 'Test Task', priority: 'high' };

  // Act: ação sob teste
  const result = createTask(input);

  // Assert: verificar o resultado
  expect(result.title).toBe('Test Task');
  expect(result.priority).toBe('high');
  expect(result.status).toBe('pending');
});
```

## Convenções de nomenclatura

```typescript
// Padrão: [unidade] [comportamento esperado] [condição]
describe('TaskService.createTask', () => {
  it('creates a task with default pending status', () => {});
  it('throws ValidationError when title is empty', () => {});
  it('trims whitespace from title', () => {});
  it('generates a unique ID for each task', () => {});
});
```

## Asserções comuns

```typescript
// Igualdade
expect(result).toBe(expected);           // Igualdade estrita (===)
expect(result).toEqual(expected);        // Igualdade profunda (objetos/arrays)
expect(result).toStrictEqual(expected);  // Igualdade profunda + tipos

// Verdade
expect(result).toBeTruthy();
expect(result).toBeFalsy();
expect(result).toBeNull();
expect(result).toBeDefined();
expect(result).toBeUndefined();

// Números
expect(result).toBeGreaterThan(5);
expect(result).toBeLessThanOrEqual(10);
expect(result).toBeCloseTo(0.3, 5);      // Ponto flutuante

// Strings
expect(result).toMatch(/pattern/);
expect(result).toContain('substring');

// Arrays / objetos
expect(array).toContain(item);
expect(array).toHaveLength(3);
expect(object).toHaveProperty('key', 'value');

// Erros
expect(() => fn()).toThrow();
expect(() => fn()).toThrow(ValidationError);
expect(() => fn()).toThrow('specific message');

// Assíncrono
await expect(asyncFn()).resolves.toBe(value);
await expect(asyncFn()).rejects.toThrow(Error);
```

## Padrões de mock

### Funções mock

```typescript
const mockFn = jest.fn();
mockFn.mockReturnValue(42);
mockFn.mockResolvedValue({ data: 'test' });
mockFn.mockImplementation((x) => x * 2);

expect(mockFn).toHaveBeenCalled();
expect(mockFn).toHaveBeenCalledWith('arg1', 'arg2');
expect(mockFn).toHaveBeenCalledTimes(3);
```

### Módulos mock

```typescript
// Mock de módulo inteiro
jest.mock('./database', () => ({
  query: jest.fn().mockResolvedValue([{ id: 1, title: 'Test' }]),
}));

// Mock de exports específicos
jest.mock('./utils', () => ({
  ...jest.requireActual('./utils'),
  generateId: jest.fn().mockReturnValue('test-id'),
}));
```

### Mock só nas fronteiras

```
Mockar:                        Não mockar:
├── Chamadas ao banco          ├── Funções utilitárias internas
├── Requisições HTTP           ├── Lógica de negócio
├── Operações de arquivo       ├── Transformações de dados
├── APIs externas              ├── Funções de validação
└── Tempo/data (quando precisar) └── Funções puras
```

## Testes React/componentes

```tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';

describe('TaskForm', () => {
  it('submits the form with entered data', async () => {
    const onSubmit = jest.fn();
    render(<TaskForm onSubmit={onSubmit} />);

    // Encontrar por papel/label acessível (não só test id)
    await screen.findByRole('textbox', { name: /title/i });
    fireEvent.change(screen.getByRole('textbox', { name: /title/i }), {
      target: { value: 'New Task' },
    });
    fireEvent.click(screen.getByRole('button', { name: /create/i }));

    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith({ title: 'New Task' });
    });
  });

  it('shows validation error for empty title', async () => {
    render(<TaskForm onSubmit={jest.fn()} />);

    fireEvent.click(screen.getByRole('button', { name: /create/i }));

    expect(await screen.findByText(/title is required/i)).toBeInTheDocument();
  });
});
```

## Testes de API / integração

```typescript
import request from 'supertest';
import { app } from '../src/app';

describe('POST /api/tasks', () => {
  it('creates a task and returns 201', async () => {
    const response = await request(app)
      .post('/api/tasks')
      .send({ title: 'Test Task' })
      .set('Authorization', `Bearer ${testToken}`)
      .expect(201);

    expect(response.body).toMatchObject({
      id: expect.any(String),
      title: 'Test Task',
      status: 'pending',
    });
  });

  it('returns 422 for invalid input', async () => {
    const response = await request(app)
      .post('/api/tasks')
      .send({ title: '' })
      .set('Authorization', `Bearer ${testToken}`)
      .expect(422);

    expect(response.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('returns 401 without authentication', async () => {
    await request(app)
      .post('/api/tasks')
      .send({ title: 'Test' })
      .expect(401);
  });
});
```

## Testes E2E (Playwright)

```typescript
import { test, expect } from '@playwright/test';

test('user can create and complete a task', async ({ page }) => {
  // Navegar e autenticar
  await page.goto('/');
  await page.fill('[name="email"]', 'test@example.com');
  await page.fill('[name="password"]', 'testpass123');
  await page.click('button:has-text("Log in")');

  // Criar tarefa
  await page.click('button:has-text("New Task")');
  await page.fill('[name="title"]', 'Buy groceries');
  await page.click('button:has-text("Create")');

  // Verificar que a tarefa aparece
  await expect(page.locator('text=Buy groceries')).toBeVisible();

  // Completar tarefa
  await page.click('[aria-label="Complete Buy groceries"]');
  await expect(page.locator('text=Buy groceries')).toHaveCSS(
    'text-decoration-line', 'line-through'
  );
});
```

## Antipadrões de teste

| Antipadrão | Problema | Melhor abordagem |
|---|---|---|
| Testar detalhe de implementação | Quebra no refactor | Testar entradas/saídas |
| Snapshot de tudo | Ninguém revisa o diff | Asserções em valores específicos |
| Estado mutável compartilhado | Testes se contaminam | Setup/teardown por teste |
| Testar código de terceiro | Perda de tempo, não é seu bug | Mock na fronteira |
| Pular testes para passar no CI | Esconde bugs | Corrigir ou remover o teste |
| `test.skip` permanente | Código morto | Remover ou corrigir |
| Asserções amplas demais | Não pegam regressões | Ser específico |
| Erro assíncrono mal tratado | Erros engolidos, falsos positivos | Sempre `await` nos testes assíncronos |
