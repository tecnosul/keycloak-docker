FROM quay.io/keycloak/keycloak:26.4.2 AS builder

# Habilita health e metrics (boas práticas)
ARG KC_HEALTH_ENABLED=true
ARG KC_METRICS_ENABLED=true

# Define o DB, necessário para o build
ENV KC_DB=postgres

# Adiciona o provedor do Apple
ADD --chown=keycloak:keycloak https://github.com/klausbetz/apple-identity-provider-keycloak/releases/download/1.16.0/apple-identity-provider-1.16.0.jar /opt/keycloak/providers/

COPY --chown=keycloak:keycloak theme/keywind /opt/keycloak/themes/keywind
# Executa o build otimizado (incorpora o provider ao Keycloak)
RUN /opt/keycloak/bin/kc.sh build

# --- Estágio 2: Imagem Final ---
FROM quay.io/keycloak/keycloak:26.4.2

# Copia os artefatos otimizados (incluindo o provider do Apple)
COPY --from=builder /opt/keycloak/ /opt/keycloak/
COPY java.config /etc/crypto-policies/back-ends/java.config
# Configurações essenciais para rodar em PaaS (como Railway)
ENV KC_HTTP_ENABLED=true
ENV KC_PROXY=edge

# O entrypoint original (kc.sh) vai automaticamente
# usar a variável $PORT fornecida pelo Railway para definir a porta.
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]

# Inicia o servidor em modo otimizado
CMD ["start", "--optimized"]
