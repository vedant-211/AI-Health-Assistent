<#
PowerShell helper to create clear, honest commits for this project.

USAGE:
1. Open PowerShell in the repository root.
2. Configure your git name/email if not already set:
   git config user.name "Your Name"
   git config user.email "you@example.com"
3. Run this script to interactively create logical commits.

This script DOES NOT fabricate timestamps or hide assistance. It helps you split the
workspace into sensible commits (initial import, feature additions, docs).
#>

function Make-Commit($message) {
    git add -A
    if ((git diff --staged --quiet) -eq $false) {
        git commit -m $message
    } else {
        Write-Host "No changes to commit for: $message"
    }
}

Write-Host "== Commit guide for AI Health Assistant =="
Write-Host "This will help you create a sequence of meaningful commits. Edit messages if needed."

Make-Commit "chore: initial import of Flutter Medical App"
Make-Commit "feat: add AI symptom analysis service (AIService)"
Make-Commit "feat: add nearby doctors feature and DoctorService"
Make-Commit "refactor: extend DoctorModel with availability fields"
Make-Commit "style: add README, LICENSE and .gitignore"

Write-Host "
Done. Review history with: git log --oneline --decorate --graph
To publish: add your remote and push:
  git remote add origin https://github.com/<your-username>/<your-repo>.git
  git branch -M main
  git push -u origin main
" 

