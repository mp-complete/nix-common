{ ... }:
{
  # @pi-unipi/notify — cross-platform notification module for pi: native
  # desktop notifications plus Gotify, Telegram, and ntfy. Ships without a
  # lockfile, so vendor the runtime tree by hand (omitting peer deps pi
  # already supplies) and apply a local hotfix to events.ts.
  # https://github.com/Neuron-Mr-White/UniPi/tree/main/packages/notify
  pi.extensions.notify = {
    pname = "@pi-unipi/notify";
    version = "2.0.15";
    hash = "sha512-e6Mul0LDNP/3/J35PDBE8xA1sWG8Ki2emogexm2ZMTfKPUV8tbSpYx0b57iFlC1v2VI0KJh0DaDQBm8gSwMcfg==";
    meta = {
      description = "Pi coding agent extension: native, Gotify, Telegram, and ntfy notifications";
      homepage = "https://github.com/Neuron-Mr-White/UniPi/tree/main/packages/notify";
    };

    build =
      {
        pkgs,
        fetchNpm,
        src,
        meta,
        passthru,
        ...
      }:
      let
        dep =
          pname: version: hash:
          fetchNpm { inherit pname version hash; };
        core =
          dep "@pi-unipi/core" "2.0.13"
            "sha512-U0tP0pQSwwUVZRP1Ox/0KJNxkeQShUMvL6EdUnXn/oAeh5Pu+91X90SFjP2MOnppEjIMLITGoJcSYyh6/JxelQ==";
        piTui =
          dep "@earendil-works/pi-tui" "0.79.4"
            "sha512-/ZhfFiHSBMH7AbDrBQIN+UWlJnl9tSEpLYICRGGMzmNfyCqX+30NYacIhyOEaD8R5rS6wJZysAOPU0yNwigbXw==";
        getEastAsianWidth =
          dep "get-east-asian-width" "1.6.0"
            "sha512-QRbvDIbx6YklUe6RxeTeleMR0yv3cYH6PsPZHcnVn7xv7zO1BHN8r0XETu8n6Ye3Q+ahtSarc3WgtNWmehIBfA==";
        growly =
          dep "growly" "1.3.0"
            "sha512-+xGQY0YyAWCnqy7Cd++hc2JqMYzlm0dG30Jd0beaA64sROr8C4nt8Yc9V5Ro3avlSUDTN0ulqP/VBKi1/lLygw==";
        isDocker =
          dep "is-docker" "2.2.1"
            "sha512-F+i2BKsFrH66iaUFc0woD8sLy8getkwTwtOBjvs56Cx4CgJDeKQeqfz8wAYiSb8JOprWhHH5p77PbmYCvvUuXQ==";
        isWsl =
          dep "is-wsl" "2.2.0"
            "sha512-fKzAra0rGJUUBwGBgNkHZuToZcn+TtXHpeCgmkMJMMYx1sQDYaCSyjJBSCa2nH1DGm7s3n1oBnohoVTBaN7Lww==";
        isexe =
          dep "isexe" "2.0.0"
            "sha512-RHxMLp9lnKHGHRng9QFhRCMbYAcVpn69smSGcq3f36xjgVVWThj4qqLbTLlq7Ssj8B+fIQ1EuCEGI2lKsyQeIw==";
        marked =
          dep "marked" "15.0.12"
            "sha512-8dD6FusOQSrpv9Z1rdNMdlSgQOIP880DHqnohobOmYLElGEqAL/JvxvuxZO16r4HtjTlfPRDC1hbvxC9dPN2nA==";
        nodeNotifier =
          dep "node-notifier" "10.0.1"
            "sha512-YX7TSyDukOZ0g+gmzjB6abKu+hTGvO8+8+gIFDsRCU2t8fLV/P2unmt+LGFaIa4y64aX98Qksa97rgz4vMNeLQ==";
        semver =
          dep "semver" "7.8.4"
            "sha512-rUCObTnP32Q08R2uuIrt7r9PlEonuTmtuXYcW6s5kjdlj3xbnwe+21yXptAUYcMAABLkYYTtnmzb3w3EDZfueA==";
        shellwords =
          dep "shellwords" "0.1.1"
            "sha512-vFwSUfQvqybiICwZY5+DAWIPLKsWO31Q91JSKl3UYv+K5c2QRPzn0qzec6QPu1Qc9eHYItiP3NdJqNVqetYAww==";
        typebox =
          dep "typebox" "1.1.38"
            "sha512-pZ0aQPmMmXoUvSbeuWf/Hzsc+avNw/Zd6VeE8CFgkVGWyuHPJvqeJJDeJqLve+K70LvjYIoleGcoJHPT17cWoA==";
        uuid =
          dep "uuid" "8.3.2"
            "sha512-+NYs2QeMWy+GWFOEm9xnn6HCDp0l7QBD7ml8zLUmJ+93Q5NF0NocErnwkTkXVFNiX3/fpC6afS8Dhb/gz7R7eg==";
        which =
          dep "which" "2.0.2"
            "sha512-BLI3Tl1TW3Pvl70l3yq3Y64i+awpwXqsGBYWkkqMtnbXgrMD+yj7rhW0kuEDxzJaYXGjEW5ogapKNMEKNMjibA==";
      in
      pkgs.runCommand "pi-ext-notify-2.0.15" { inherit meta passthru; } ''
                  unpack() {
                    mkdir -p "$1"
                    tar -xzf "$2" --strip-components=1 -C "$1"
                  }

                  unpack "$out" "${src}"
                  unpack "$out/node_modules/@pi-unipi/core" "${core}"
                  unpack "$out/node_modules/@earendil-works/pi-tui" "${piTui}"
                  unpack "$out/node_modules/get-east-asian-width" "${getEastAsianWidth}"
                  unpack "$out/node_modules/growly" "${growly}"
                  unpack "$out/node_modules/is-docker" "${isDocker}"
                  unpack "$out/node_modules/is-wsl" "${isWsl}"
                  unpack "$out/node_modules/isexe" "${isexe}"
                  unpack "$out/node_modules/marked" "${marked}"
                  unpack "$out/node_modules/node-notifier" "${nodeNotifier}"
                  unpack "$out/node_modules/semver" "${semver}"
                  unpack "$out/node_modules/shellwords" "${shellwords}"
                  unpack "$out/node_modules/typebox" "${typebox}"
                  unpack "$out/node_modules/uuid" "${uuid}"
                  unpack "$out/node_modules/which" "${which}"

                  # Local hotfix: @pi-unipi/notify 2.0.15 only registers the
                  # ask-user prompt listener when the event is enabled at
                  # session_start. If the user enables it from config/settings
                  # during a running Pi session, prompt notifications still do
                  # not fire until Pi restarts. Keep the listener installed and
                  # load the latest config when the question is actually asked.
                  substituteInPlace "$out/events.ts" \
                    --replace-fail \
                      'import { buildAskUserPromptMessage } from "./ask-user-prompt-message.js";' \
                      'import { buildAskUserPromptMessage } from "./ask-user-prompt-message.js";
        import { loadConfig } from "./settings.js";'

                  substituteInPlace "$out/events.ts" \
                    --replace-fail \
                      'if (eventKey === "agent_end") continue; // handled separately below' \
                      'if (eventKey === "agent_end" || eventKey === "ask_user_prompt") continue; // handled separately below'

                  substituteInPlace "$out/events.ts" \
                    --replace-fail \
                      '  // Listen for rpiv:ask-user:prompt from @juicesharp/rpiv-ask-user-question
          const askUserConfig = config.events["ask_user_prompt"];
          if (askUserConfig?.enabled) {
            unsubs.push(pi.events.on(ASK_USER_PROMPT_EVENT, (payload: unknown) => {
              const title = `Pi — ''${BUILTIN_EVENTS.ask_user_prompt.label}`;
              const message = buildAskUserPromptMessage(payload);
              dispatchNotification(pi, title, message, askUserConfig.platforms, "ask_user_prompt", config, cwd).catch(
                () => {
                  // Silently ignore — background notification failure is non-blocking.
                }
              );
            }));
          }' \
                      '  // Listen for ask-user prompts from UniPi and rpiv. This listener is
          // always installed and reloads config when the prompt is emitted so
          // enabling ask_user_prompt during a running Pi session takes effect
          // without a restart.
          const askUserHandler = (payload: unknown) => {
            const currentConfig = loadConfig();
            const askUserConfig = currentConfig.events["ask_user_prompt"];
            if (!askUserConfig?.enabled) return;

            const title = `Pi — ''${BUILTIN_EVENTS.ask_user_prompt.label}`;
            const message = buildAskUserPromptMessage(payload);
            dispatchNotification(
              pi,
              title,
              message,
              askUserConfig.platforms,
              "ask_user_prompt",
              currentConfig,
              cwd
            ).catch(() => {
              // Silently ignore — background notification failure is non-blocking.
            });
          };
          unsubs.push(pi.events.on(UNIPI_EVENTS.ASK_USER_PROMPT, askUserHandler));
          unsubs.push(pi.events.on(ASK_USER_PROMPT_EVENT, askUserHandler));'
      '';
  };
}
