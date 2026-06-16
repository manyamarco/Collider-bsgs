#!/bin/bash

echo "Compilando Collider para Linux..."

# Path do compilador do PureBasic (ajuste conforme sua instalação no Linux)
# Por padrão assumimos que o PUREBASIC_HOME está definido ou o compilar está na pasta
PB_COMPILER="${PUREBASIC_HOME:-/usr/share/purebasic}/compilers/pbcompiler"

if [ ! -f "$PB_COMPILER" ]; then
    echo "Erro: Compilador do PureBasic não encontrado em $PB_COMPILER"
    echo "Defina a variável PUREBASIC_HOME apontando para a pasta raiz do PureBasic."
    exit 1
fi

# Cria um fake GCC para forçar o -no-pie (Corrige erros de R_X86_64_PC32 em distribuições modernas)
mkdir -p .tmp_gcc
echo '#!/bin/bash' > .tmp_gcc/gcc
echo '/usr/bin/gcc -no-pie -z execstack "$@"' >> .tmp_gcc/gcc
chmod +x .tmp_gcc/gcc

# Adiciona o fake_gcc ao PATH temporariamente
export PATH="$(pwd)/.tmp_gcc:$PATH"

# Compila o arquivo
"$PB_COMPILER" Collider.pb -e ../x64/Collider_Linux -t -c

# Limpa o workaround
rm -rf .tmp_gcc

echo "Compilação concluída! Executável gerado em ../x64/Collider_Linux"
