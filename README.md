# Shared Make Code

This repo holds mostly makefile snippets, and some auxilliary scripts used by our makefiles.

The point is to share makefile code instead of duplicating it in every repo.

We do this with `git subtree`.

# What's `git subtree`?

Read this: https://andrey.nering.com.br/2016/git-submodules-vs-subtrees/

# I've created a new repo, how do inject this common code into it?

Let's take the repo `spice` as an example. We want to connect it to this repo (`makes`).

First, decide where in the repo you want it to sit. A reasonable open is at the repo root in a directory called `makes`.

Then add a remote to `makes` so it's easy to refer to it:

```~/binaris/spice $ git remote add makes git@github.com:binaris/makes.git```

Now you can add the subtree:

```~/binaris/spice $ git subtree add --squash --prefix=makes/ makes master```

This says "take the `makes` repo's `master` branch and transplant it into the `makes/` directory in this repo (`spice`).

We use `--squash` because otherwise `makes`'s entire git history will be copied into `spice` and we probably don't want that.

That's it. The files are there now, you can use them.

# I made changes to the `makes` subtree in some repo. How do I share them back?

If I change some of the common make source on my own repo and I want to contribute these changes back into the shared `makes` repo, then I can do `git subtree push --prefix=makes/ makes master`.

# The `makes` repo has been updated, and I want my own repo to get those changes.

You can "pull" upstream changes with:

`git subtree pull --squash --prefix=makes/ makes master`

