#!/bin/bash

# Diretórios de backup
BACKUP_DIR="./docker_backup"
IMAGES_DIR="${BACKUP_DIR}/images"
CONTAINERS_DIR="${BACKUP_DIR}/containers"
VOLUMES_DIR="${BACKUP_DIR}/volumes"
RUN_CONFIG_FILE="${BACKUP_DIR}/run_containers.sh"

# Cria os diretórios necessários, caso não existam
mkdir -p "$IMAGES_DIR" "$CONTAINERS_DIR" "$VOLUMES_DIR"

####################################
# Função de backup das imagens Docker
####################################
backup_images() {
  echo "Fazendo backup das imagens Docker..."
  docker images --format "{{.Repository}}:{{.Tag}}" | while read IMAGE; do
    if [ "$IMAGE" != "<none>:<none>" ]; then
      # Substitui / e : por _ para evitar problemas com diretórios
      FILENAME=$(echo "$IMAGE" | sed 's#[/:]#_#g').tar
      OUTPUT_PATH="${IMAGES_DIR}/${FILENAME}"
      mkdir -p "$(dirname "$OUTPUT_PATH")"
      echo "Salvando imagem $IMAGE em $OUTPUT_PATH"
      docker save "$IMAGE" -o "$OUTPUT_PATH"
    fi
  done
}

####################################
# Função de backup dos containers
####################################
backup_containers() {
  echo "Fazendo backup dos containers..."
  docker ps -a -q | while read CONTAINER; do
    NAME=$(docker inspect --format='{{.Name}}' "$CONTAINER" | sed 's#^/##')
    echo "Exportando container $NAME"
    docker export "$CONTAINER" -o "${CONTAINERS_DIR}/${NAME}.tar"
  done
}

####################################
# Função de backup dos volumes
####################################
backup_volumes() {
  echo "Fazendo backup dos volumes..."
  docker volume ls -q | while read VOLUME; do
    echo "Salvando volume $VOLUME"
    docker run --rm -v "$VOLUME":/volume -v "$(pwd)/$VOLUMES_DIR":/backup alpine \
      sh -c "cd /volume && tar czf /backup/${VOLUME}.tar.gz ."
  done
}

####################################
# Função para gerar arquivo com os comandos de execução dos containers
####################################
backup_run_config() {
  echo "Gerando arquivo com os comandos para recriar os containers..."
  echo "#!/bin/bash" > "$RUN_CONFIG_FILE"
  echo "" >> "$RUN_CONFIG_FILE"
  # Para cada container, gere um comando docker run com as configurações obtidas via docker inspect
  for container in $(docker ps -a -q); do
    run_cmd=$(docker inspect -f 'docker run -d --name {{.Name}} {{range $port, $bindings := .HostConfig.PortBindings}}{{range $binding := $bindings}} -p {{$binding.HostPort}}:{{$port}} {{end}}{{end}}{{range .Mounts}} -v {{.Source}}:{{.Destination}} {{end}}{{range .Config.Env}} -e {{.}} {{end}}{{.Config.Image}} {{.Path}}{{range .Args}} {{.}}{{end}}' "$container")
    # Remove a barra inicial do nome (pois .Name vem com "/" no início)
    run_cmd=$(echo "$run_cmd" | sed 's/--name \//--name /')
    echo "$run_cmd" >> "$RUN_CONFIG_FILE"
  done
  chmod +x "$RUN_CONFIG_FILE"
  echo "Arquivo de execução gerado: $RUN_CONFIG_FILE"
}

####################################
# Função para restaurar as imagens Docker
####################################
restore_images() {
  echo "Restaurando imagens Docker..."
  for file in ${IMAGES_DIR}/*.tar; do
    echo "Carregando imagem a partir de $file"
    docker load -i "$file"
  done
}

####################################
# Função para restaurar os volumes
####################################
restore_volumes() {
  echo "Restaurando volumes..."
  for file in ${VOLUMES_DIR}/*.tar.gz; do
    VOLUME=$(basename "$file" .tar.gz)
    echo "Criando volume $VOLUME"
    docker volume create "$VOLUME"
    echo "Restaurando dados para o volume $VOLUME"
    docker run --rm -v "$VOLUME":/volume -v "$(pwd)/$VOLUMES_DIR":/backup alpine \
      sh -c "cd /volume && tar xzf /backup/${VOLUME}.tar.gz"
  done
}

####################################
# Função para restaurar os containers utilizando o arquivo de configuração
####################################
restore_containers() {
  if [ -f "$RUN_CONFIG_FILE" ]; then
    echo "Executando arquivo de configuração para recriar os containers..."
    # Lê cada linha do arquivo de configuração
    while IFS= read -r line; do
      # Ignora linhas vazias ou comentários
      if [[ "$line" =~ ^#.* ]] || [ -z "$line" ]; then
        continue
      fi
      # Extrai o nome do container (após --name)
      NAME=$(echo "$line" | sed -n 's/.*--name[[:space:]]\+\([^[:space:]]\+\).*/\1/p')
      if [ -n "$NAME" ]; then
        if docker container inspect "$NAME" > /dev/null 2>&1; then
          echo "Container $NAME já existe. Removendo-o..."
          docker rm -f "$NAME"
        fi
      fi
      echo "Executando: $line"
      eval "$line"
    done < "$RUN_CONFIG_FILE"
  else
    echo "Arquivo de configuração ($RUN_CONFIG_FILE) não encontrado. Recrie os containers manualmente."
  fi
}

####################################
# Função de uso do script
####################################
usage() {
  echo "Uso: $0 {backup|restore}"
  exit 1
}

# Verifica se o parâmetro foi passado
if [ $# -ne 1 ]; then
  usage
fi

case $1 in
  backup)
    backup_images
    backup_containers
    backup_volumes
    backup_run_config
    ;;
  restore)
    restore_images
    restore_volumes
    restore_containers
    ;;
  *)
    usage
    ;;
esac

echo "Operação concluída."
