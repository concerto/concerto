# Release Process

## 1. Check for open milestone issues

```
gh issue list --milestone <milestone>
```

Ensure all issues are closed or deferred before proceeding.

## 2. Update the VERSION file

```
echo "<version>" > VERSION
```

## 3. Commit the version bump on a release branch

```
git checkout -b release/v<version>
git add VERSION
git commit -m "Bump version to <version>"
```

## 4. Push the branch and open a pull request

```
git push origin release/v<version>
gh pr create --title "Bump version to <version>" --body "Release prep for v<version>"
```

## 5. Merge the pull request

Merge via the GitHub UI or CLI:

```
gh pr merge --merge
```

## 6. Tag the release from main

```
git checkout main
git pull origin main
git tag -a v<version> -m "v<version>"
git push origin v<version>
```

This triggers the release workflow which builds multi-arch Docker images (amd64 + arm64) and pushes them to GHCR tagged as `<version>`.

## 7. Create the GitHub release

```
gh release create v<version> --title "v<version>" --prerelease --generate-notes
```

Add `--draft` if you want to review the generated notes before publishing.
