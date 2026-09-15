import { readFile } from "node:fs/promises"
import { fileURLToPath } from "node:url"

const skills = [
  {
    id: "prism-lifecycle",
    name: "Prism Lifecycle",
    description: "Route Prism work to the complete Story or Epic lifecycle.",
  },
  {
    id: "prism-story",
    name: "Prism Story",
    description: "Run the full Prism Story lifecycle in the current coding agent.",
  },
  {
    id: "prism-epic",
    name: "Prism Epic",
    description: "Run the full Prism Epic lifecycle in the current coding agent.",
  },
].map((skill) => ({
  ...skill,
  url: new URL(`../../plugins/prism/prefixed-skills/${skill.id}/SKILL.md`, import.meta.url),
}))

function body(markdown) {
  return markdown.replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/, "")
}

export default {
  id: "prism",
  async setup(ctx) {
    const bundled = await Promise.all(
      skills.map(async (skill) => ({
        ...skill,
        content: body(await readFile(skill.url, "utf8")),
      })),
    )

    await ctx.skill.transform((editor) => {
      for (const skill of bundled) {
        editor.add({
          id: skill.id,
          name: skill.name,
          description: skill.description,
          location: fileURLToPath(skill.url),
          content: skill.content,
        })
      }
    })
  },
}
