# ~/.zshrc

# Prüfen, ob die Shell interaktiv ist
if [[ $- != *i* ]] ; then
    # Shell is non-interactive.  Be done now!
    return
fi


# Define aliases
if [[ -f ~/.aliases ]]; then
    source  ~/.aliases
fi

# Pfad für zusätzliche Vervollständigungen (zsh-completions) hinzufügen
fpath=(/usr/share/zsh/site-functions /usr/share/zsh/vendor-completions $fpath)

# Erweitertes Zsh-Completion-System aktivieren
autoload -Uz compinit && compinit

# --- ERGÄNZUNG: Komfortable Tab-Vervollständigung ---
zstyle ':completion:*' menu select # Aktiviert das Pfeiltasten-Auswahlmenü im Terminal
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Ignoriere Groß-/Kleinschreibung

# Plugins laden
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- ERGÄNZUNG: Tastaturbindungen für Autosuggestions ---
# Mit Pfeiltaste-Rechts oder End-Taste nimmst du den grauen Textvorschlag an
bindkey '^[[C' forward-word
bindkey '^[[F' end-of-line
# Mit Strg+Leertaste nimmst du exakt ein Wort des Vorschrags an
bindkey '^X^F' forward-word 

# Verlauf (History) Einstellungen
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY     # Fügt History an statt zu überschreiben
setopt SHARE_HISTORY      # Teilt die History in Echtzeit mit allen offenen Terminals

# Globale Zsh-Skripte einbinden (Arch-Standard statt Bash-Verzeichnis)
if [ -d /etc/zsh/zshrc.d/ ]; then
    for f in /etc/zsh/zshrc.d/*.zsh; do
        [ -r "$f" ] && . "$f"
    done
    unset f
fi

# Dynamischer griechischer Prompt für Zsh
_generate_greek_prompt() {
    local -a PROMPTS
    PROMPTS=(
        "Σ" "ς" "Ε" "ε" "Ρ" "ρ" "Τ" "τ" "Υ" "υ" "Θ" "θ" "Ι" "ι" "Ο" "ο" "Π" "π"
        "Α" "α" "Σ" "σ" "Δ" "δ" "Φ" "φ" "Γ" "γ" "Η" "η" "Ξ" "ξ" "Κ" "κ" "Λ" "λ"
        "Ζ" "ζ" "Χ" "χ" "Ψ" "ψ" "Ω" "ω" "Β" "β" "Ν" "ν" "Μ" "μ" 
    )

    # Zufälligen Index berechnen (Zsh-Arrays starten bei Index 1)
    local random_index=$(( (RANDOM % ${#PROMPTS[@]}) + 1 ))
    local ignition="${PROMPTS[$random_index]}"

    # %c zeigt nur den aktuellen Ordnernamen. Ersetze %c durch %~ für den vollen Pfad.
    PROMPT="%F{yellow}%c%f %F{green}${ignition}%f %F{blue}>>%f "
}

# Aktiviert die dynamische Aktualisierung bei jedem Befehl
autoload -Uz add-zsh-hook
add-zsh-hook precmd _generate_greek_prompt


# Fortune-Funktion für Zitate
local_fortune() {
    local quote_file="$HOME/.local/bin/quotes/quotes"
    
    if [[ -f "$quote_file" ]]; then
        awk -v RS='(^|\n)%\n' 'BEGIN{srand()} {a[NR]=$0} END{if(NR>0) print a[int(rand()*NR)+1]}' "$quote_file"
    else
        echo "Hinweis: Zitatdatei unter $quote_file nicht gefunden."
    fi
}

# Zitat beim Start des Terminals ausgeben (Raute entfernen zum Aktivieren)
# local_fortune


