;;; org-roam-peek.el --- Peek into nodes with posframe.

;; Copyright (C) 2022 Dominik Keller.


;; Author: Dominik Keller
;; Version: 0.1.0
;; Package-Requires: ((emacs "26.0")(posframe "1.0.0")(helm "2.0.0")(org "9.4"))
;; Keywords: org-mode, roam, convenience, posframe
;; URL: https://www.github.com/domse007/org-roam-peek

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;; Show a posframe to see inside a node without following it.

;;; Code:
(require 'posframe)
(require 'org-roam)
(require 'org)

;;; Options:
(defgroup org-roam-peek nil
  "Using posframe to peek into org-roam links."
  :prefix "org-roam-peek")

(defcustom org-roam-peek-posframe-poshandler
  #'posframe-poshandler-frame-top-right-corner
  "Poshandler for the posframe. posframe-poshandler-* family of functions are
alternatives"
  :group 'org-roam-peek
  :type 'function)

(defcustom org-roam-peek-posframe-border-width 1
  "The widht of the border of the posframe."
  :group 'org-roam-peek
  :type 'number)

(defcustom org-roam-peek-posframe-width nil
  "The width of the posframe."
  :group 'org-roam-peek
  :type 'number)

(defcustom org-roam-peek-posframe-height nil
  "The height of the posframe."
  :group 'org-roam-peek
  :type 'number)

(defcustom org-roam-peek-buffer-name "*org-roam-peek*"
  "Name of the buffer that is shown in the posframe."
  :group 'org-roam-peek
  :type 'number)

(defface org-roam-peek-posframe-border
  '((t (:inherit default :background "gray50")))
  "Border color of the org-roam-peek-buffer."
  :group 'org-roam-peek)

;;; Variables:
(defvar org-roam-peek--enabled nil
  "Wheter the mode is enabled or not.")

(defvar org-roam-peek--shown nil
  "Indicator if a buffer is shown.")

(defvar org-roam-peek--last-id ""
  "Id of the last visible id.")

;;; Functions:
(defun org-roam-peek--pst-cmd ()
  "Function that is called to see if the cursor is hovering over a link."
  (let* ((object (org-element-context))
         (type (car object))
         (link-info (car (cdr object))))
    (when (and (eq type 'link) (not org-roam-peek--shown))
      (let ((link-type (plist-get link-info :type))
            (link-id (plist-get link-info :path)))
        (when (string-equal link-type "id")
          (get-buffer-create org-roam-peek-buffer-name)
          (with-current-buffer org-roam-peek-buffer-name
	    ;; must only be reloaded if the id has changed.
	    (unless (string-equal org-roam-peek--last-id link-id)
	      (delete-region (point-min) (point-max))
	      (insert-file-contents (car (org-roam-id-find link-id nil)))
	      (let ((inhibit-message t))(org-mode))) ; supress minibuffer output
            (org-roam-peek--show-posframe (buffer-name)))
	  (setq org-roam-peek--shown t
		org-roam-peek--last-id link-id))))
    (when (and (not (eq type 'link)) org-roam-peek--shown)
      (progn (posframe-hide org-roam-peek-buffer-name)
             (setq org-roam-peek--shown nil)))))

(defun org-roam-peek--show-posframe (buffer)
  "Show a posframe with the peeked BUFFER."
  (apply #'posframe-show buffer
         :position (point)
         :poshandler org-roam-peek-posframe-poshandler
         :border-width org-roam-peek-posframe-border-width
         :border-color
         (face-attribute 'org-roam-peek-posframe-border :background nil t)
         (list :width (or org-roam-peek-posframe-width
                          (/ (window-width) 3))
               :height (or org-roam-peek-posframe-height
                           (/ (window-height) 3)))))

;;;###autoload
(define-minor-mode org-roam-peek-mode
  "Toggle org-roam link peeking."
  :lighter " pk"
  (if org-roam-peek--enabled
      (progn (setq org-roam-peek--enabled nil)
	     (remove-hook 'post-command-hook 'org-roam-peek--pst-cmd)
             (kill-buffer org-roam-peek-buffer-name)
             (setq org-roam-peek--shown nil))
    (when (posframe-workable-p)
      (setq org-roam-peek--enabled t)
      (add-hook 'post-command-hook 'org-roam-peek--pst-cmd))))

(provide 'org-roam-peek)

;;; org-roam-peek.el ends here.
