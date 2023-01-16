#!/usr/bin/env groovy

import java.nio.file.*

/*
 * Removes a link and the target of the link, if the target is a file or
 * is missing (broken link).
 *
 * Keeps directories (no recursive delete).
 *
 * Only runs when told that eager clean up is on and the exit code of the
 * main part of the process is zero (success). Exits with the same exit
 * code as the main part of the process.
 */
def remove(path)
{
    if (!Files.exists(path, LinkOption.NOFOLLOW_LINKS))
    {
        // If it doesn't exist, say it has been removed.
        // This handles when a call is made to remove a broken symbolic link.
        return true
    }

    if (Files.isDirectory(path, LinkOption.NOFOLLOW_LINKS))
    {
        return false
    }

    final def TAG = 'EAGER_CLEANUP'

    if (Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS))
    {
        Files.delete(path)
        println("${TAG}: Removed regular file ${path}")
        return true
    }

    if (Files.isSymbolicLink(path))
    {
        def target = Files.readSymbolicLink(path)
        if (path.parent)
        {
            target = path.parent.resolve(target)
        }
        // println("${TAG}: Symbolic link ${path} target is ${target}")
        def removed = remove(target)
        if (removed)
        {
            Files.delete(path)
            println("${TAG}: Removed symbolic link ${path}")
            return true
        }
    }

    return false
}

def exitCode = 0

if (args.length >= 2)
{
    try
    {
        def doRemovals = Boolean.parseBoolean(args[0])
        exitCode = Integer.parseInt(args[1])
        def files = Arrays.asList(args).subList(2, args.length)

        if (doRemovals && exitCode == 0)
        {
            files.each
            {
                def file = new File(it)
                remove(file.toPath())
            }
        }
    }
    catch (NumberFormatException e)
    {
        System.err.println("The exit code doesn't seem to be a number. Will not do anything in removeInput.groovy")
    }
}
else
{
    System.err.println("Too few arguments to do anything in removeInput.groovy")
}

System.exit(exitCode)
