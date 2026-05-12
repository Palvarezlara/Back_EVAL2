# ============================================================
# STAGE 1 — Dependencias
# ============================================================
FROM node:18-alpine AS deps

WORKDIR /app

# Copiar solo los archivos de dependencias para aprovechar el caché
COPY package*.json ./

# Instalar solo dependencias de producción sin exigir package-lock.json
RUN npm install --omit=dev

# ============================================================
# STAGE 2 — Build / pruning (opcional lint/test)
# ============================================================
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
# Instalar todas las dependencias sin requerir package-lock.json
RUN npm install

COPY . .

# ============================================================
# STAGE 3 — Imagen final de producción
# ============================================================
FROM node:18-alpine AS production

# Metadatos
LABEL maintainer="Innovatech Chile"
LABEL description="Backend API REST - Node.js/Express"
LABEL version="1.0"

# Crear usuario no-root para mínimo privilegio
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copiar dependencias de producción desde la etapa 'deps'
COPY --from=deps /app/node_modules ./node_modules

# Copiar el código fuente desde la etapa 'builder'
COPY --from=builder /app/server.js ./
COPY --from=builder /app/package*.json ./

# Ajustar permisos al usuario no-root
RUN chown -R appuser:appgroup /app

# Cambiar al usuario no-root
USER appuser

# Puerto que expone la API
EXPOSE 3000

# Variable de entorno para producción
ENV NODE_ENV=production

# Healthcheck — verifica que la API responde
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD wget -qO- http://localhost:3000/api/usuarios || exit 1

# Comando de inicio
CMD ["node", "server.js"]
