#!/bin/bash
# ==========================================
# 🎮 MINECRAFT VPS INSTALLER - DAYTONA
# ==========================================
# Usage (pick ONE):
#   Method 1: curl -sL URL | bash
#   Method 2: bash <(curl -sL URL)
#   Method 3: curl -sL URL -o vps.sh && bash vps.sh
# ==========================================

# ── Colors ──────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'
WHITE='\033[1;37m'; NC='\033[0m'

# ── If running via pipe, download self and re-exec ──────
if [ ! -t 0 ]; then
    echo -e "${YELLOW}⏳ Downloading script...${NC}"
    SELF_URL="https://raw.githubusercontent.com/manixshop/Minecraft_Server1/main/install.sh"
    SELF_TMP="/tmp/mc_vps_installer.sh"
    curl -sL "$SELF_URL" -o "$SELF_TMP"
    if [ -s "$SELF_TMP" ]; then
        chmod +x "$SELF_TMP"
        echo -e "${GREEN}✅ Downloaded. Launching...${NC}"
        echo ""
        exec bash "$SELF_TMP" "$@"
    else
        echo -e "${RED}❌ Download failed.${NC}"
        echo -e "Run manually:${NC}"
        echo -e "  ${CYAN}curl -sL $SELF_URL -o /tmp/vps.sh && bash /tmp/vps.sh${NC}"
        exit 1
    fi
fi

# ── Config ──────────────────────────────────────────────
VPS_DIR="$HOME/vps_data"
ENV_FILE="$VPS_DIR/.vps_env"
SHORTCUT_FILE="$HOME/.mc_vps_connect.sh"
mkdir -p "$VPS_DIR"

# ── Helpers ─────────────────────────────────────────────
log()  { echo -e "$1"; }
bar()  {
    local t="$1"
    echo -ne "${YELLOW}⏳ $t ${NC}["
    for i in 1 2 3 4 5 6 7 8 9 10; do sleep 0.15; echo -n "█"; done
    echo -e "] ${GREEN}DONE${NC}"
}
press_enter() { echo -e "${YELLOW}Enter baraye edame...${NC}"; read -r; }

# ── Main Menu ───────────────────────────────────────────
show_menu() {
    clear
    echo -e "${RED}════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}       🎮 MINECRAFT VPS MANAGER - DAYTONA              ${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} 🚀  Sakht VPS Jadid"
    echo -e "  ${CYAN}[2]${NC} 🔄  Restart VPS"
    echo -e "  ${CYAN}[3]${NC} 🔌  Taghir Port"
    echo -e "  ${CYAN}[4]${NC} 🔑  Taghir Kalame Kheyei"
    echo -e "  ${CYAN}[5]${NC} 🗑️   Pak Kardan VPS"
    echo -e "  ${CYAN}[6]${NC} 📊  Vaziat"
    echo -e "  ${CYAN}[7]${NC} ❌  Khorooj"
    echo ""
    echo -e "${RED}════════════════════════════════════════════════════════${NC}"
    echo -ne "${WHITE}🔹 Gozine [1-7]: ${NC}"
    read -r C
    echo ""
    case "$C" in
        1) do_create ;;
        2) do_restart ;;
        3) do_port ;;
        4) do_keyword ;;
        5) do_clean ;;
        6) do_status ;;
        7) exit 0 ;;
        *) log "${RED}❌ Namotabar!${NC}"; sleep 1; show_menu ;;
    esac
}

# ── CREATE VPS ──────────────────────────────────────────
do_create() {
    clear
    log "${WHITE}⚙️  Sakht Machine Majazi${NC}"
    log "${RED}────────────────────────────────────────${NC}"

    if [ -f "$VPS_DIR/ubuntu.qcow2" ]; then
        log "${YELLOW}⚠️  VPS ghabli vojood dare.${NC}"
        echo -ne "${WHITE}Bazsazi? (y/N): ${NC}"; read -r R
        [ "$R" != "y" ] && [ "$R" != "Y" ] && show_menu && return
    fi

    echo -ne "${BLUE}RAM GB [8]: ${NC}";     read -r RAM_GB;      RAM_GB=${RAM_GB:-8}
    echo -ne "${BLUE}CPU cores [4]: ${NC}";  read -r CPU_CORES;  CPU_CORES=${CPU_CORES:-4}
    echo -ne "${BLUE}Extra disk GB [10]: ${NC}"; read -r DISK_GB; DISK_GB=${DISK_GB:-10}
    echo -ne "${BLUE}Username [ubuntu]: ${NC}";  read -r USR;      USR=${USR:-ubuntu}
    echo -ne "${BLUE}Password [1234]: ${NC}";    read -r PASS;     PASS=${PASS:-1234}
    echo -ne "${BLUE}SSH port [2222]: ${NC}";    read -r PORT;     PORT=${PORT:-2222}
    echo -ne "${BLUE}Quick keyword [vps]: ${NC}"; read -r KW;      KW=${KW:-vps}
    echo ""

    # ── 1) Dependencies ─────────────────────────────────
    log "${YELLOW}[1/5] Nasb vabastegi ha...${NC}"
    if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi
    $SUDO apt-get update -y > /dev/null 2>&1
    $SUDO apt-get install -y qemu-system-x86 qemu-utils wget \
        cloud-image-utils curl tmux netcat-openbsd > /dev/null 2>&1

    if ! command -v qemu-system-x86_64 &>/dev/null; then
        log "${RED}❌ QEMU nasb nashod!${NC}"
        log "${CYAN}sudo apt install qemu-system-x86${NC}"
        press_enter; show_menu; return
    fi
    log "${GREEN}  ✅ Vabastegi ha OK${NC}"

    # ── 2) Download image ────────────────────────────────
    log "${YELLOW}[2/5] Download Ubuntu 22.04...${NC}"
    if [ ! -f "$VPS_DIR/ubuntu.qcow2" ]; then
        wget --progress=dot:giga \
            "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img" \
            -O "$VPS_DIR/ubuntu.qcow2" 2>&1 | tail -1
        if [ ! -s "$VPS_DIR/ubuntu.qcow2" ]; then
            log "${RED}❌ Download namovafagh!${NC}"
            press_enter; show_menu; return
        fi
        chmod 666 "$VPS_DIR/ubuntu.qcow2"
    else
        log "${GREEN}  ✅ Image mojood ast${NC}"
    fi

    # ── 3) Cloud-init ────────────────────────────────────
    log "${YELLOW}[3/5] Tanzimat Cloud-Init...${NC}"
    cat > "$VPS_DIR/user-data" <<UDEOF
#cloud-config
hostname: mc-vps
ssh_pwauth: true
chpasswd:
  list: |
    ${USR}:${PASS}
  expire: false
package_update: true
packages:
  - curl wget git net-tools ufw htop tmux nano
  - openjdk-17-jdk screen unzip apt-transport-https
  - ca-certificates gnupg lsb-release
runcmd:
  - mkdir -p /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /tmp/docker.gpg
  - gpg --dearmor -o /etc/apt/keyrings/docker.gpg /tmp/docker.gpg || cp /tmp/docker.gpg /etc/apt/keyrings/docker.gpg
  - echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable" > /etc/apt/sources.list.d/docker.list
  - apt-get update
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin || apt-get install -y docker.io
  - systemctl enable docker
  - systemctl start docker
  - usermod -aG docker ${USR}
  - docker run --rm hello-world || echo "Docker test skipped"
  - ufw allow 22/tcp
  - ufw allow 25565:25570/tcp
  - ufw allow 8080/tcp
  - ufw allow 3000/tcp
  - ufw allow 80/tcp
  - ufw allow 443/tcp
  - ufw --force enable
  - echo "READY" > /tmp/vps-ready
  - echo "Docker: $(docker --version 2>/dev/null || echo 'not installed')" >> /tmp/vps-ready
UDEOF

    cloud-localds "$VPS_DIR/seed.img" "$VPS_DIR/user-data" > /dev/null 2>&1
    if [ ! -s "$VPS_DIR/seed.img" ]; then
        log "${RED}❌ cloud-localds khata. Nasb mojadad...${NC}"
        $SUDO apt-get install -y cloud-image-utils > /dev/null 2>&1
        cloud-localds "$VPS_DIR/seed.img" "$VPS_DIR/user-data" > /dev/null 2>&1
    fi
    log "${GREEN}  ✅ Cloud-Init OK${NC}"

    # ── 4) Expand disk ───────────────────────────────────
    log "${YELLOW}[4/5] Afzayesh disk +${DISK_GB}G...${NC}"
    qemu-img resize "$VPS_DIR/ubuntu.qcow2" "+${DISK_GB}G" > /dev/null 2>&1
    log "${GREEN}  ✅ Disk OK${NC}"

    # ── 5) Save config ───────────────────────────────────
    log "${YELLOW}[5/5] Zakhire tanzimat...${NC}"
    cat > "$ENV_FILE" <<ENVEOF
RAM_GB=${RAM_GB}
CPU_CORES=${CPU_CORES}
USR=${USR}
PASS=${PASS}
PORT=${PORT}
KW=${KW}
ENVEOF

    # ── Create shortcut script ───────────────────────────
    # NOTE: heredoc is UNQUOTED so variables expand NOW
    cat > "$SHORTCUT_FILE" <<SCEOF
#!/bin/bash
source "$ENV_FILE"
QEMU_PID=\$(pgrep -f "qemu-system-x86_64.*ubuntu.qcow2" | head -1)
if [ -z "\$QEMU_PID" ]; then
    echo "⚠️  VPS off. Starting..."
    tmux kill-session -t vps 2>/dev/null
    sleep 1
    tmux new-session -d -s vps "qemu-system-x86_64 -hda $VPS_DIR/ubuntu.qcow2 -m ${RAM_GB}G -smp ${CPU_CORES} -drive file=$VPS_DIR/seed.img,format=raw -nographic -netdev user,id=net0,hostfwd=tcp::${PORT}-:22 -device e1000,netdev=net0"
    echo "⏳ Booting..."; sleep 12
fi
echo ""
echo -e "\033[0;32m═══════════════════════════════════\033[0m"
echo -e "\033[1;37m  🔗 Connecting to VPS\033[0m"
echo -e "\033[0;32m═══════════════════════════════════\033[0m"
echo -e "  👤 ${USR}"
echo -e "  🔑 ${PASS}"
echo -e "  🚀 ssh ${USR}@localhost -p ${PORT}"
echo ""
read -p "Enter to connect > "
if nc -z -w3 localhost ${PORT} 2>/dev/null; then
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${USR}@localhost -p ${PORT}
else
    tmux attach-session -t vps 2>/dev/null || echo "❌ VPS not available"
fi
SCEOF
    chmod +x "$SHORTCUT_FILE"

    # ── Add alias to bashrc ──────────────────────────────
    sed -i '/# MC-VPS/d' ~/.bashrc 2>/dev/null
    sed -i "/alias ${KW}=/d" ~/.bashrc 2>/dev/null
    cat >> ~/.bashrc <<BASHEOF

# MC-VPS Quick Connect
alias ${KW}='bash ${SHORTCUT_FILE}'
BASHEOF
    eval "alias ${KW}='bash ${SHORTCUT_FILE}'" 2>/dev/null

    log "${GREEN}  ✅ Shortcut '${KW}' fa'al shod${NC}"
    log "${GREEN}✅ Nasb kamel!${NC}"
    sleep 1

    # ── Boot ─────────────────────────────────────────────
    do_boot
}

# ── BOOT QEMU ───────────────────────────────────────────
do_boot() {
    source "$ENV_FILE" 2>/dev/null
    local R="${RAM_GB:-8}" C="${CPU_CORES:-4}" P="${PORT:-2222}"

    clear
    log "${GREEN}════════════════════════════════════════════════════════${NC}"
    log "${WHITE}  🚀 Starting VPS...${NC}"
    log "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo ""

    # Get public IP
    PUB_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || curl -s --max-time 5 icanhazip.com 2>/dev/null || echo "N/A")

    # Kill old
    tmux kill-session -t vps 2>/dev/null
    pkill -f "qemu-system-x86_64.*ubuntu.qcow2" 2>/dev/null
    sleep 2

    # Launch QEMU in tmux
    tmux new-session -d -s vps "qemu-system-x86_64 \
        -hda $VPS_DIR/ubuntu.qcow2 \
        -m ${R}G \
        -smp ${C} \
        -drive file=$VPS_DIR/seed.img,format=raw \
        -nographic \
        -netdev user,id=net0,hostfwd=tcp::${P}-:22 \
        -device e1000,netdev=net0"

    sleep 2

    # Verify
    if ! tmux has-session -t vps 2>/dev/null; then
        log "${RED}❌ QEMU shoru nashod!${NC}"
        log "${YELLOW}Etmam kon: sudo apt install qemu-system-x86${NC}"
        press_enter; show_menu; return
    fi

    log "${GREEN}════════════════════════════════════════════════════════${NC}"
    log "${WHITE}  🎉 VPS Zende Ast!${NC}"
    log "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo ""
    log "  🌐 IP Omoomi  : ${CYAN}${PUB_IP}${NC}"
    log "  👤 Username   : ${CYAN}${USR:-ubuntu}${NC}"
    log "  🔑 Password   : ${CYAN}${PASS:-1234}${NC}"
    log "  ⚙️  Manabe    : ${CYAN}${R}G RAM | ${C} cores${NC}"
    log "  🚀 SSH        : ${YELLOW}ssh ${USR:-ubuntu}@${PUB_IP} -p ${P}${NC}"
    log "  📺 Console    : ${YELLOW}tmux attach -t vps${NC}"
    echo ""
    log "${PURPLE}════════════════════════════════════════════════════════${NC}"
    log "  ⚡ Etsal saree: ${CYAN}${KW:-vps}${WHITE} ro tu terminal bezan"
    log "${PURPLE}════════════════════════════════════════════════════════${NC}"
    echo ""
    log "${YELLOW}  Enter baraye baz kardan console (Ctrl+B -> D baraye khorooj)${NC}"
    read -p "  > "
    tmux attach-session -t vps
}

# ── RESTART ─────────────────────────────────────────────
do_restart() {
    if [ ! -f "$VPS_DIR/ubuntu.qcow2" ]; then
        log "${RED}❌ VPS peyda nashod!${NC}"; sleep 2; show_menu; return
    fi
    log "${GREEN}🔄 Restart...${NC}"
    tmux kill-session -t vps 2>/dev/null
    pkill -f "qemu-system-x86_64.*ubuntu.qcow2" 2>/dev/null
    sleep 2
    do_boot
}

# ── PORT CONFIG ─────────────────────────────────────────
do_port() {
    clear
    source "$ENV_FILE" 2>/dev/null
    log "${YELLOW}═══ Tanzimat Port ═══${NC}"
    log "Hale hazer: ${CYAN}${PORT:-2222}${NC} → VM:22"
    echo ""
    echo -ne "${BLUE}Port jadid host [2222]: ${NC}"; read -r NP; PORT=${NP:-2222}
    cat > "$ENV_FILE" <<ENVEOF
RAM_GB=${RAM_GB:-8}
CPU_CORES=${CPU_CORES:-4}
USR=${USR:-ubuntu}
PASS=${PASS:-1234}
PORT=${PORT}
KW=${KW:-vps}
ENVEOF
    log "${GREEN}✅ Port be ${PORT} taghir kard${NC}"
    sleep 2; show_menu
}

# ── KEYWORD CONFIG ──────────────────────────────────────
do_keyword() {
    clear
    source "$ENV_FILE" 2>/dev/null
    log "${YELLOW}═══ Tanzimat Keyword ═══${NC}"
    log "Hale hazer: ${CYAN}${KW:-vps}${NC}"
    echo ""
    echo -ne "${BLUE}Kalame jadid [vps]: ${NC}"; read -r NK; KW=${NK:-vps}

    # Remove old alias
    OLD_KW=$(grep '# MC-VPS' -A1 ~/.bashrc 2>/dev/null | grep alias | head -1 | cut -d"'" -f1 | sed 's/alias //')
    [ -n "$OLD_KW" ] && sed -i "/alias ${OLD_KW}=/d" ~/.bashrc 2>/dev/null
    sed -i '/# MC-VPS/d' ~/.bashrc 2>/dev/null

    # Add new
    cat >> ~/.bashrc <<BASHEOF

# MC-VPS Quick Connect
alias ${KW}='bash ${SHORTCUT_FILE}'
BASHEOF
    eval "alias ${KW}='bash ${SHORTCUT_FILE}'" 2>/dev/null

    # Update env
    cat > "$ENV_FILE" <<ENVEOF
RAM_GB=${RAM_GB:-8}
CPU_CORES=${CPU_CORES:-4}
USR=${USR:-ubuntu}
PASS=${PASS:-1234}
PORT=${PORT:-2222}
KW=${KW}
ENVEOF

    log "${GREEN}✅ Keyword be '${KW}' taghir kard${NC}"
    sleep 2; show_menu
}

# ── STATUS ──────────────────────────────────────────────
do_status() {
    clear
    log "${CYAN}═══ Vaziat VPS ═══${NC}"
    echo ""
    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
        log "  👤 User     : ${CYAN}${USR}${NC}"
        log "  🔑 Password : ${CYAN}${PASS}${NC}"
        log "  🔌 Port     : ${CYAN}${PORT}${NC}"
        log "  💾 RAM      : ${CYAN}${RAM_GB}G${NC}"
        log "  ⚡ Keyword  : ${CYAN}${KW}${NC}"
        echo ""
        QPID=$(pgrep -f "qemu-system-x86_64.*ubuntu.qcow2" | head -1)
        [ -n "$QPID" ] && log "  🟢 Vaziat: ${GREEN}Dar hale ejra (PID $QPID)${NC}" || log "  🔴 Vaziat: ${RED}Motevaghef${NC}"
        tmux has-session -t vps 2>/dev/null && log "  📺 Console: ${GREEN}Fa'al${NC}" || log "  📺 Console: ${RED}Gheir fa'al${NC}"
        echo ""
        [ -f "$VPS_DIR/ubuntu.qcow2" ] && log "  ✅ ubuntu.qcow2 ($(du -h "$VPS_DIR/ubuntu.qcow2" | cut -f1))" || log "  ❌ ubuntu.qcow2 peyda nashod"
        [ -f "$VPS_DIR/seed.img" ] && log "  ✅ seed.img" || log "  ❌ seed.img peyda nashod"
        [ -f "$SHORTCUT_FILE" ] && log "  ✅ shortcut.sh" || log "  ❌ shortcut.sh peyda nashod"
    else
        log "${RED}  ❌ Hich VPS-i nasb nashode${NC}"
    fi
    echo ""
    press_enter; show_menu
}

# ── CLEAN ───────────────────────────────────────────────
do_clean() {
    echo -e "${RED}⚠️  Pak kardan VPS...${NC}"
    source "$ENV_FILE" 2>/dev/null
    tmux kill-session -t vps 2>/dev/null
    pkill -f "qemu-system-x86_64.*ubuntu.qcow2" 2>/dev/null
    sed -i '/# MC-VPS/d' ~/.bashrc 2>/dev/null
    sed -i "/alias ${KW:-vps}=/d" ~/.bashrc 2>/dev/null
    rm -rf "$VPS_DIR" "$SHORTCUT_FILE"
    log "${GREEN}✅ Pak shod!${NC}"
    sleep 2; show_menu
}

# ── START ───────────────────────────────────────────────
show_menu