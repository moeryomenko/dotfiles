if test -z "${XDG_RUNTIME_DIR}"; then
        export XDG_RUNTIME_DIR=/tmp/${UID}-runtime-dir
        if ! test -d "${XDG_RUNTIME_DIR}"; then
                mkdir "${XDG_RUNTIME_DIR}"
                chmod 0700 "${XDG_RUNTIME_DIR}"
        fi
fi

if [[ -z "$XDG_CONFIG_HOME" ]]; then
	export XDG_CONFIG_HOME=$HOME/.config
fi

[[ -f ~/.bashrc ]] && . ~/.bashrc
