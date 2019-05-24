(in-package "ACL2")

(include-book "centaur/esim/defmodules" :dir :system)
(include-book "centaur/gl/gl" :dir :system)
(include-book "centaur/aig/g-aig-eval" :dir :system)
(include-book "centaur/esim/stv/stv-top" :dir :system)
(include-book "centaur/esim/stv/stv-debug" :dir :system)
(include-book "centaur/4v-sexpr/top" :dir :system)
(include-book "tools/plev-ccl" :dir :system)
(include-book "centaur/misc/memory-mgmt" :dir :system)
(include-book "misc/without-waterfall-parallelism" :dir :system)

(without-waterfall-parallelism
(def-gl-clause-processor my-glcp))

(plev)
(set-slow-alist-action :break)
(set-debugger-enable t)
(break-on-error t)

(value-triple (set-max-mem (* 3 (expt 2 30))))

;;  loading stuff for SAT
(include-book "centaur/gl/bfr-satlink" :dir :system)
(tshell-ensure)
(gl::gl-satlink-mode)
(gl::gl-bdd-mode)

;; loading config for glucose
(defun my-glucose-config ()
  (declare (xargs :guard t))
  (satlink::make-config :cmdline "glucose"
                        :verbose t
                        :mintime 1/2
                        :remove-temps t))
(defattach gl::gl-satlink-config my-glucose-config)


;; ---------------- END GENERAL BOOK LOADING ------------------------------


;; reading Verilog and extracting modules
(defmodules *translation*
  (vl2014::make-vl-loadconfig
   :start-files (list "core8_template.v")))


;; ----------------- END TEMPLATE----------------------------------------


