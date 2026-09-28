function NoteCard({ note, onDelete }) {
  return (
    <article
      className="
        group
        relative
        cursor-pointer
        rounded-2xl
        border
        border-[#252A33]
        bg-[#181B21]
        p-6
        transition-all
        duration-200
        hover:-translate-y-1
        hover:border-[#60A5FA]
        hover:shadow-[0_8px_30px_rgba(96,165,250,0.12)]
      "
    >
      <button
        type="button"
        onClick={() => onDelete(note.id)}
        className="
          absolute
          right-4
          top-4
          flex
          h-9
          w-9
          cursor-pointer
          items-center
          justify-center
          rounded-lg
          bg-red-500/10
          text-2xl
          font-medium
          text-red-400
          opacity-0
          transition-all
          duration-200
          group-hover:opacity-100
          hover:bg-red-500/20
          hover:text-red-300
        "
      >
        <span className="-translate-y-0.5">
          ×
        </span>
      </button>

      <h2
        className="
          mb-3
          text-xl
          font-semibold
          text-[#F1F5F9]
        "
      >
        {note.title}
      </h2>

      <p className="leading-7 text-[#94A3B8]">
        {note.body}
      </p>
    </article>
  );
}

export default NoteCard;