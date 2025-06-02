// components/SocialFeed.tsx
import { useState, useEffect } from 'react'
import { useAuth } from '../context/AuthContext'
import { useCanisters } from '../context/CanisterContext'
import type { Post } from '../../../declarations/UserCanister/UserCanister.did'

const SocialFeed = () => {
    const { identity } = useAuth()
    const { userCanister } = useCanisters()
    const [posts, setPosts] = useState<Post[]>([])
    const [newPost, setNewPost] = useState('')

    useEffect(() => {
        if (!userCanister) return
        userCanister.getAllPosts().then((posts) => {
            setPosts(posts.map(([id, post]) => post))
        })
    }, [userCanister])

    // In handleCreatePost
    const handleCreatePost = async () => {
        if (!newPost.trim() || !userCanister || !identity) return
        try {
            await userCanister.createPost(newPost)
            setNewPost('')
            const updatedPosts = await userCanister.getAllPosts()
            setPosts(updatedPosts.map(([id, post]) => post))
        } catch (error) {
            console.error('Failed to create post:', error)
        }
    }

    return (
        <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-xl font-bold mb-4">Social Feed</h2>
            <div className="mb-4">
                <textarea
                    className="w-full p-2 border rounded"
                    placeholder="What's happening?"
                    value={newPost}
                    onChange={(e) => setNewPost(e.target.value)}
                />
                <button
                    onClick={handleCreatePost}
                    className="mt-2 px-4 py-2 bg-blue-500 text-white rounded"
                >
                    Post
                </button>
            </div>
            <div className="space-y-4">
                {posts.map(post => (
                    <div key={post.id} className="border-b pb-4">
                        <p className="font-semibold">{post.authorId}</p>
                        <p>{post.content}</p>
                    </div>
                ))}
            </div>
        </div>
    )
}

export default SocialFeed
