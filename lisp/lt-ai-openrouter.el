;;; lt-ai-openrouter.el --- gptel through OpenRouter -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(defvar lt-openrouter-models
  '((z-ai/glm-5.3-flash
     :capabilities (tool-use reasoning json))
    (z-ai/glm-5.3
     :capabilities (tool-use reasoning json))
    (deepseek/deepseek-v4-flash
     :capabilities (tool-use))
    (deepseek/deepseek-v4-pro
     :capabilities (tool-use reasoning))
    (qwen/qwen3-235b-a22b-2507
     :capabilities (tool-use))
    (qwen/qwen3-coder-480b-a35b
     :capabilities (tool-use))
    (z-ai/glm-4.7
     :capabilities (tool-use)))
  "Models offered by OpenRouter.")

(defun lt-openrouter-api-key ()
  "Return the OpenRouter API key."
  (auth-source-pick-first-password :host "openrouter.ai" :user "apikey"))

(with-eval-after-load 'gptel
  (setq gptel-backend (gptel-make-openai "OpenRouter"
                        :host "openrouter.ai"
                        :endpoint "/api/v1/chat/completions"
                        :stream t
                        :key #'lt-openrouter-api-key
                        :models lt-openrouter-models)
        gptel-model 'z-ai/glm-5.3-flash))

(with-eval-after-load 'lt-gptel-magit
  (setq lt-gptel-magit-model 'deepseek/deepseek-v4-pro))

(with-eval-after-load 'agent-shell
  (setq agent-shell-opencode-authentication
        (agent-shell-opencode-make-authentication :api-key #'lt-openrouter-api-key)))

(provide 'lt-ai-openrouter)
;;; lt-ai-openrouter.el ends here
