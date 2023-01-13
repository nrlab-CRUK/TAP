#!/usr/bin/env groovy

import java.nio.file.*

/*
 * Removes a link and the target of the link, if the target is a file or
 * is missing (broken link).
 *
 * Keeps directories (no recursive delete).
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

args.each
{
    def file = new File(it)
    remove(file.toPath())
}
